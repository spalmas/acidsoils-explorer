/*
 *  DATA AND LAYERS FOR acidsoils-explorer SHINY APP
 * This runs in Google Earth Engine
 */ ////////////////////

/* ////////////////////
 *  LSIB: Large Scale International Boundary Polygons, Simplified
 * Create Sub-saharan layer by removing northern countries
 */ ////////////////////
var SSA = ee.FeatureCollection("USDOS/LSIB_SIMPLE/2017")
  .filter(ee.Filter.eq('wld_rgn', 'Africa'))
  .filter(ee.Filter.neq('country_co', 'CV'))  //CaboVerde
  .filter(ee.Filter.neq('country_co', 'MO'))  //Morroco
  .filter(ee.Filter.neq('country_co', 'SP'))  //Spain
  .filter(ee.Filter.neq('country_co', 'PO'))  //Portugal
  .filter(ee.Filter.neq('country_co', 'AG'))  //Algeria
  .filter(ee.Filter.neq('country_co', 'TS'))  //Tunisia
  .filter(ee.Filter.neq('country_co', 'LY'))  //Lybia
  .filter(ee.Filter.neq('country_co', 'WI'))  //Western Sahara
  .filter(ee.Filter.neq('country_co', 'EG')) //Egypt
  .filter(ee.Filter.neq('country_co', 'UU')) //Koualou Area and Abyei Area
  .filter(ee.Filter.neq('country_co', 'CN'))  //Comoros has no pH Data
  .filter(ee.Filter.neq('country_co', 'MF'))  //Mayotte has no pH Datas
  .filter(ee.Filter.neq('country_co', 'TP'))
  .filter(ee.Filter.neq('country_na', 'Halaib Triangle'));  //Halaib triangle
  
/* ////////////////////
 *  CROPLAND IMAGES
 */ ////////////////////
// 2018 C3S Global Land Cover products 
var C3S_10 = ee.Image("users/palmasforest/C3S-LC-L4-LCCS-Map-300m-P1Y-2018-v2_1_1_SSA").eq(10);//.selfMask();   
var C3S_11 = ee.Image("users/palmasforest/C3S-LC-L4-LCCS-Map-300m-P1Y-2018-v2_1_1_SSA").eq(11);//.selfMask();   
var C3S_12 = ee.Image("users/palmasforest/C3S-LC-L4-LCCS-Map-300m-P1Y-2018-v2_1_1_SSA").eq(12);//.selfMask();   
var C3S_20 = ee.Image("users/palmasforest/C3S-LC-L4-LCCS-Map-300m-P1Y-2018-v2_1_1_SSA").eq(20);//.selfMask();   
var C3S_100croparea = C3S_10.add(C3S_11).add(C3S_12).add(C3S_20).gte(1).multiply(ee.Image.pixelArea());//.selfMask();

var C3S_30 = ee.Image("users/palmasforest/C3S-LC-L4-LCCS-Map-300m-P1Y-2018-v2_1_1_SSA").eq(30).multiply(ee.Image.pixelArea()).divide(0.75);//.selfMask();     //Mosaic 50-100%. Only use 75% of the area of the pixel
var C3S_40 = ee.Image("users/palmasforest/C3S-LC-L4-LCCS-Map-300m-P1Y-2018-v2_1_1_SSA").eq(40).multiply(ee.Image.pixelArea()).divide(0.25);//.selfMask();     //Mosaic 0-50%. Only use 25% of the area of the pixel
var C3S_croparea = C3S_100croparea.add(C3S_30).add(C3S_40).rename("C3S Crop Area");  //combine all C3S areas

/* ////////////////////
 *  PH top layer from africasoils
 * We want to have these categories:
 * <5.6", "5.6-6.5", "6.6-7.3", "7.4-7.8", ">7.8"
 */ ////////////////////
var ph = ee.Image('users/palmasforest/af_PHIHOX_T__M_sd1_250m').clip(SSA).rename('SSAph');
var dumbmask = ph.gte(0); //creating a dumb mask because getting total croparea was causing problems
var acidmask = ph.lt(55).selfMask().rename("Acid Mask"); //creating a mask with areas with  pH <= 5.5. [0,1]
var mask55 = ph.gte(55); //creating a mask with areas with  pH <= 5.5. [0,1]


/* ////////////////////
 *  Acid cropland from C3S and COPERNICUS
 */ ////////////////////
//Create acid cropland area C3S
var C3S_croparea = C3S_croparea.multiply(dumbmask).rename('C3S_croparea');  //[0,1]
var C3S_croparea_acid = C3S_croparea.multiply(acidmask).rename('C3S_croparea_acid');  //[0,1]

//Create acid cropland area from COPERNICUS
var COPERNICUS_croparea = COPERNICUS_croparea.multiply(dumbmask).rename('COPERNICUS_croparea');  //[0,1]
var COPERNICUS_croparea_acid = COPERNICUS_croparea.multiply(acidmask).rename('COPERNICUS_croparea_acid');  //[0,1]
//Convert acidcrop to area per pixel to sum
//var acidcroparea = acidcrop.multiply(ee.Image.pixelArea());

/* ////////////////////
 *  ANALYSIS AND EXPORT
 */ ////////////////////
 
// C3S_ Total cropland area by country
var C3S_croparea_table = C3S_croparea.reduceRegions({collection: SSA, reducer: ee.Reducer.sum()});
Export.table.toDrive({
  collection: C3S_croparea_table,
  description:'C3S_croparea_table',
  folder: 'acidsoils', fileFormat: 'GeoJSON'
});
// C3S_Get area of cropland with high acidity by country. pH<55
var C3S_croparea_acid_table = C3S_croparea_acid.reduceRegions({collection: SSA, reducer: ee.Reducer.sum()});
Export.table.toDrive({
  collection: C3S_croparea_acid_table,
  description:'C3S_croparea_acid_table',
  folder: 'acidsoils', fileFormat: 'GeoJSON'
});

// COPERNICUS cropland area by country
var COPERNICUS_croparea_table = COPERNICUS_croparea.reduceRegions({ collection: SSA, reducer: ee.Reducer.sum()});
Export.table.toDrive({
  collection: COPERNICUS_croparea_table,
  description:'COPERNICUS_croparea_table',
  folder: 'acidsoils', fileFormat: 'GeoJSON'
});
// COPERNICUS cropland with high acidity by country. pH<55
var COPERNICUS_croparea_acid_table = COPERNICUS_croparea_acid.reduceRegions({collection: SSA, reducer: ee.Reducer.sum()});
Export.table.toDrive({
  collection: COPERNICUS_croparea_acid_table,
  description:'COPERNICUS_croparea_acid_table',
  folder: 'acidsoils', fileFormat: 'GeoJSON'
});
// Get area of cropland with high acidity by country. pH>=55 & ph<=70


////// ADDING MAPS TO DISPLAY //////
//Map.addLayer(crop_ph);
//Map.addLayer(SSAcroparea_acid56);
//Map.addLayer(C3S);