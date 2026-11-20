// A deliberately labelled Toronto demonstration catalogue. Prices, hours, noise
// and travel estimates are fixtures, never live venue or accessibility claims.
export const AREAS = [
  {id:'annex',name:'The Annex',lat:43.670,lng:-79.405},
  {id:'leslieville',name:'Leslieville',lat:43.663,lng:-79.329},
  {id:'liberty',name:'Liberty Village',lat:43.639,lng:-79.420},
  {id:'downtown',name:'Downtown',lat:43.653,lng:-79.383},
  {id:'midtown',name:'Midtown',lat:43.706,lng:-79.398},
  {id:'junction',name:'The Junction',lat:43.665,lng:-79.464}
];
export const INTERESTS = [
  {id:'games',name:'Games',icon:'dice'}, {id:'art',name:'Art & culture',icon:'art'},
  {id:'food',name:'Food',icon:'food'}, {id:'coffee',name:'Coffee',icon:'coffee'},
  {id:'outdoors',name:'Outdoors',icon:'sun'}, {id:'music',name:'Music',icon:'music'}
];
const make = (id,name,venue,area,lat,lng,cost,tags,noise,indoor,stepFree,theme,description,url) => ({
  id,name,venue,area,lat,lng,cost,tags,noise,indoor,stepFree,theme,description,url,
  duration:90, windows:[[660,1320]], dataSource:'demo', verifiedAt:null
});
export const CATALOG = [
  make('college-games','A little friendly competition','Snakes & Lattes College','Little Italy',43.655,-79.414,22,['games','food','coffee'],2,true,null,'games','Pick a game, order something good, and let the conversation happen.','https://www.snakesandlattes.com/college'),
  make('ago','Get a fresh perspective','Art Gallery of Ontario','Grange Park',43.654,-79.392,30,['art'],1,true,null,'art','An unhurried gallery wander with plenty to talk about afterwards.','https://ago.ca/'),
  make('riverdale','Catch the city slowing down','Riverdale Park East','Riverdale',43.669,-79.355,0,['outdoors','coffee'],1,false,null,'park','A skyline view and a slow walk. Bring your own favourite drink.','https://www.toronto.ca/explore-enjoy/parks-recreation/'),
  make('harbourfront','Take the scenic route','Harbourfront waterfront','Harbourfront',43.638,-79.381,0,['outdoors','art'],1,false,null,'water','A waterfront wander with room for a long-overdue catch-up.','https://harbourfrontcentre.com/'),
  make('reference-library','A quiet kind of hangout','Toronto Reference Library','Yorkville',43.671,-79.387,0,['art','coffee'],1,true,null,'library','Browse something unexpected, then trade your best discoveries.','https://www.torontopubliclibrary.ca/torontoreferencelibrary/'),
  make('kensington','Make an afternoon of it','Kensington Market','Kensington',43.655,-79.400,18,['food','art','outdoors'],2,false,null,'market','A neighbourhood wander with a flexible stop for a bite.','https://www.destinationtoronto.com/neighbourhoods/westside/kensington-market/'),
  make('bentway','Find your urban playground','The Bentway','Fort York',43.638,-79.404,0,['outdoors','art'],2,false,null,'park','Public art and a change of scenery under the Gardiner.','https://thebentway.ca/'),
  make('gardiner','A small creative escape','Gardiner Museum','Museum',43.668,-79.393,20,['art','coffee'],1,true,null,'art','Take a closer look at ceramics, craft, and a slower afternoon.','https://www.gardinermuseum.on.ca/'),
  make('bellwoods','The picnic everyone needed','Trinity Bellwoods Park','Queen West',43.647,-79.414,12,['outdoors','food'],2,false,null,'picnic','A bring-your-own picnic, a blanket, and no complicated agenda.','https://www.toronto.ca/explore-enjoy/parks-recreation/'),
  make('distillery','Wander somewhere different','Distillery Historic District','Distillery',43.650,-79.359,16,['art','coffee','outdoors'],2,false,null,'market','A relaxed stroll, independent shops, and a coffee stop.','https://www.thedistillerydistrict.com/'),
  make('music','An evening with a soundtrack','Toronto Music Garden','Waterfront',43.637,-79.394,0,['music','outdoors'],1,false,null,'water','Explore the garden together. Check the venue for any live programming.','https://harbourfrontcentre.com/'),
  make('sample-studio','Make something together','MeetHalfway sample studio','Downtown · fictional demo venue',43.653,-79.384,24,['art','games','coffee'],1,true,true,'studio','A fictional, step-free workshop used to test accessibility constraints.','')
];
export const DEMO_MEMBERS = [
  {id:'alex',name:'Alex',initials:'AL',color:'sage',card:{areaId:'annex',maxSpend:30,maxTravel:45,mode:'transit',interests:['games','art','coffee'],earliest:960,latest:1320,quiet:false,indoors:false,stepFree:false}},
  {id:'maya',name:'Maya',initials:'MA',color:'peach',card:{areaId:'leslieville',maxSpend:25,maxTravel:45,mode:'transit',interests:['games','food','art'],earliest:1020,latest:1350,quiet:false,indoors:false,stepFree:false}},
  {id:'jordan',name:'Jordan',initials:'JO',color:'lavender',card:{areaId:'liberty',maxSpend:35,maxTravel:40,mode:'transit',interests:['games','coffee','outdoors'],earliest:990,latest:1380,quiet:false,indoors:false,stepFree:false}}
];
