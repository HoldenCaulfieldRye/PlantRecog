module.exports = process.env.PLANT_COV
  ? require('./lib-cov/plant')
  : require('./lib/plant');
