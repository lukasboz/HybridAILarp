import {initializeApp} from 'firebase-admin/app';
import {getFirestore, FieldValue} from 'firebase-admin/firestore';
import {getMessaging} from 'firebase-admin/messaging';
import {onDocumentCreated, onDocumentUpdated} from 'firebase-functions/v2/firestore';

initializeApp();
const db = getFirestore();
const config = {region: 'northamerica-northeast2', maxInstances: 2, retry: true};
const descriptions = {
  created: 'A plan is ready for your preferences.', joined: 'Someone joined your plan.',
  card: 'Shared preferences changed.', options: 'Activity options changed.',
  proposal: 'A proposal is ready for your vote.', vote: 'A vote was updated.',
  confirmed: 'Everyone agreed. Your plan is confirmed.', plan: 'Your plan details changed.',
};

// The inbox is idempotent by event ID. A short delivery lease prevents duplicate
// trigger deliveries from sending the same push concurrently. No card data,
// names, email addresses or raw notes enter the notification payload.
export const planNotifications = onDocumentCreated({...config, document: 'rooms/{roomId}/events/{eventId}'}, async event => {
  const change = event.data?.data();
  if (!change || !descriptions[change.type]) return;
  const room = await db.doc(`rooms/${event.params.roomId}`).get();
  if (!room.exists || room.data().deleting) return;
  const data = room.data();
  if (!data.memberIds.includes(change.actorId)) return;
  const members = data.memberIds.filter(uid => uid !== change.actorId);
  for (const uid of members) {
    const inbox = db.doc(`users/${uid}/inbox/${room.id}_${event.params.eventId}`);
    const acquired = await db.runTransaction(async tx => {
      const old = (await tx.get(inbox)).data();
      if (old?.sent) return false;
      if ((old?.leaseUntil?.toMillis() ?? 0) > Date.now()) {
        throw new Error('A delivery lease is active; retry after its owner finishes.');
      }
      // One notification per person/room/minute bounds spam from active votes.
      const gate = db.doc(`users/${uid}/delivery/${event.params.roomId}`);
      const last = (await tx.get(gate)).data();
      if ((last?.at?.toMillis() ?? 0) > Date.now() - 60000 && change.type !== 'confirmed') {
        tx.set(inbox, {roomId: room.id, type: change.type, createdAt: FieldValue.serverTimestamp(), sent: true});
        return false;
      }
      tx.set(inbox, {roomId: room.id, type: change.type, createdAt: FieldValue.serverTimestamp(),
        leaseUntil: new Date(Date.now() + 120000), sent: false});
      tx.set(gate, {at: FieldValue.serverTimestamp()});
      return true;
    });
    if (!acquired) continue;
    const devices = await db.collection(`users/${uid}/devices`).limit(20).get();
    if (devices.empty) { await inbox.update({sent: true, leaseUntil: FieldValue.delete()}); continue; }
    const outcome = await getMessaging().sendEachForMulticast({
      fids: devices.docs.map(doc => doc.data().fid),
      notification: {title: 'MeetHalfway', body: descriptions[change.type]},
      data: {roomId: room.id},
      android: {collapseKey: room.id, notification: {tag: room.id}},
      apns: {headers: {'apns-collapse-id': room.id}},
      webpush: {notification: {tag: room.id}, fcmOptions: {
        link: `https://meethalfway-2026-e43ca6.web.app/?room=${encodeURIComponent(room.id)}`,
      }},
    });
    const cleanup = db.batch();
    let transientFailure = false;
    outcome.responses.forEach((response, i) => {
      if (['messaging/registration-token-not-registered', 'messaging/invalid-registration-token'].includes(response.error?.code)) {
        cleanup.delete(devices.docs[i].ref);
      } else if (!response.success) { transientFailure = true; }
    });
    cleanup.update(inbox, {sent: !transientFailure, leaseUntil: FieldValue.delete()});
    await cleanup.commit();
    if (transientFailure) throw new Error('Transient push delivery failure; retry the event.');
  }
});

// Membership changes are not written as client events by departing identities.
export const membershipNotifications = onDocumentUpdated({...config, document: 'rooms/{roomId}'}, async event => {
  const before = event.data.before.data(), after = event.data.after.data();
  if (after.deleting || JSON.stringify(before.memberIds) === JSON.stringify(after.memberIds)) return;
  const ref = db.doc(`rooms/${event.params.roomId}/events/member-${event.id.replace(/[^a-zA-Z0-9_-]/g, '').slice(0, 120)}`);
  await db.runTransaction(async tx => {
    if ((await tx.get(ref)).exists) return;
    tx.create(ref, {type: 'plan', actorId: after.ownerId, revision: after.revision, createdAt: FieldValue.serverTimestamp()});
  });
});
