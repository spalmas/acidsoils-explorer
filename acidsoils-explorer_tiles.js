/* ////////////////////
 * TILES OF PH IN CROPLANDS USED FOR ACIDSOILS-EXPLORER SHINY APP (leaflet)
 * This script runs in Google Earth Engine
 *
 * Shiny App: https://github.com/spalmas/acidsoils-explorer
 * Analysis of pH distribution (tables, graphs) are in https://github.com/spalmas/acidsoils
 */ ////////////////////

/* 
 *  LSIB: Large Scale International Boundary Polygons, Simplified
 * Create Sub-saharan layer by removing northern African countries
 */
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
  
/* 
 *  CROPLAND IMAGE
 * For the Shiny App, we will only base the croplands in the ESACCI-LC-L4 classification.
 */ 
var cropland = ee.Image("users/palmasforest/ESACCI-LC-L4-LC10-Map-20m-P1Y-2016-v10").eq(4).clip(SSA).selfMask().rename('Cropland');   


/* 
 *  PH top layer from africasoils
 */ 
var ph = ee.Image('users/palmasforest/af_PHIHOX_T__M_sd1_250m').clip(SSA).rename('SSAph');


/* 
 * pH IN CROPLAND AND VISUZALIZATION
 */ 
var ph_cropland = cropland.multiply(ph).rename('pH');

var ph_cropland_51 = ph_cropland.gte(51);
var ph_cropland_56 = ph_cropland.gte(56);
var ph_cropland_65 = ph_cropland.gte(65);
var ph_cropland_73 = ph_cropland.gte(73);
var ph_cropland_78 = ph_cropland.gte(78);

var ph_cropland_class = ph_cropland_51.add(ph_cropland_56).add(ph_cropland_65).add(ph_cropland_73).add(ph_cropland_78);
// pH visualization of the croplands
//* <5.6", "5.6-6.5", "6.6-7.3", "7.4-7.8", ">7.8"
var ph_cropland_tile = ph_cropland_class.visualize({
  min: 1,
  max: 5,
  palette: ["#FF6B00", "#F7A84D", "#EEE49A", "#A77A6D", '#5F0F40']
});


/* 
 * EXPORT TILES TO CLOUD
 */ 
// Request payload size exceeds the limit: 4194304 bytes.

Export.map.toCloudStorage({
  image: ph_cropland_tile,
  description: 'ph_cropland_class',
  bucket: 'acidsoils-ssa',
  maxZoom:10,
  //region: SSA,
  skipEmptyTiles: true
});

////// ADDING MAPS TO DISPLAY //////
//Map.addLayer(crop_ph);
//Map.addLayer(SSAcroparea_acid56);
Map.addLayer(ph_cropland_tile);