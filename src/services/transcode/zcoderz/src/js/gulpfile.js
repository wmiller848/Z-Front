var gulp = require('gulp');
var coffee = require('gulp-coffee');
var coffeelint = require('gulp-coffeelint');
var concat = require('gulp-concat');
var compress = require('gulp-yuicompressor');
var sourcemaps = require('gulp-sourcemaps');
var jasmine = require('gulp-jasmine-phantom');
var plumber = require('gulp-plumber');
var del = require('del');
var order = require('gulp-order');

var paths = {
  vendor: 'src/vendor/*.js',
  spec: 'spec/*.coffee',
  src: 'src/*.coffee',
  tmp: 'bin/tmp/*.coffee.js',
  dev: 'bin/dev/*.js'
};

var STATE_OK = 0,
    STATE_ERR = 1;

var state = STATE_OK;

function handleError (err) {
  console.log(err.toString());
  this.emit('end');
  state = STATE_ERR;
  setTimeout(function() {
    state = STATE_OK;
  }, 200)
}

gulp.task('clean', function(cb) {
  return del(['bin'], cb);
});

gulp.task('compile', ['clean'], function() {
  if (state === STATE_OK) {
    return gulp.src(paths.src)
    	.pipe(plumber(handleError))
    	//.pipe(sourcemaps.init())
    	.pipe(coffeelint())
      .pipe(coffeelint.reporter())
    	.pipe(coffee())
      .pipe(concat('zcoderz.coffee.js'))
      //.pipe(sourcemaps.write())
      .pipe(gulp.dest('bin/tmp'));
  } else if (state === STATE_ERR) {
    console.log('State is "error" skipping...');
  }
});

gulp.task('compile:dev', ['compile'], function() {
  if (state === STATE_OK) {
    return gulp.src([paths.vendor, paths.tmp])
      .pipe(order([paths.vendor, paths.tmp], {base: './'}))
      .pipe(concat('zcoderz.js'))
      .pipe(gulp.dest('bin/dev'));
  } else if (state === STATE_ERR) {
    console.log('State is "error" skipping...');
  }
});

gulp.task('compile:release', ['compile:dev'], function() {
  if (state === STATE_OK) {
    return gulp.src(paths.dev)
    	.pipe(plumber(handleError))
      .pipe(compress({
        type: 'js'
      }))
      .pipe(concat('zcoderz.min.js'))
      .pipe(gulp.dest('bin/release'));
  } else if (state === STATE_ERR) {
    console.log('State is "error" skipping...');
  }
});

gulp.task('compile:spec', ['compile:release'], function() {
  if (state === STATE_OK) {
  	return gulp.src(paths.spec)
  		.pipe(plumber(handleError))
  		.pipe(coffeelint())
      .pipe(coffeelint.reporter())
    	.pipe(coffee())
    	.pipe(concat('zcoderz.spec.js'))
    	.pipe(gulp.dest('bin/spec'));
  } else if (state === STATE_ERR) {
    console.log('State is "error" skipping...');
  }
});

gulp.task('spec', ['compile:spec'], function() {
  if (state === STATE_OK) {
    return gulp.src(['bin/dev/zcoderz.js', 'bin/spec/zcoderz.spec.js'])
    	.pipe(jasmine({
    		integration: true
    	}));
  } else if (state === STATE_ERR) {
    console.log('State is "error" skipping...');
  }
});

gulp.task('watch', function() {
  gulp.watch('src/*.coffee', ['spec']);
});

gulp.task('default', ['spec']);
