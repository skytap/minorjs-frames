/**
 * Copyright 2016 Skytap Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

var fs        = require('fs'),
    copyright = fs.readFileSync('./banner.txt', 'utf8');

module.exports = function (grunt) {
  grunt.loadNpmTasks('grunt-banner');
  grunt.loadNpmTasks('grunt-contrib-coffee');
  grunt.loadNpmTasks('grunt-mocha-test');

  grunt.registerTask('build', [
    'coffee:compile',
    'usebanner:copyright'
  ]);

  grunt.registerTask('tests', [
    'mochaTest:unit'
  ]);

  grunt.initConfig({
    coffee : {
      compile : {
        expand  : true,
        flatten : true,
        cwd     : 'src',
        src     : [ '*.coffee' ],
        dest    : 'lib',
        ext     : '.js'
      }
    },

    mochaTest : {
      options : {
        reporter : 'dot',
        require  : [
          'should'
        ]
      },
      unit : {
        src : [
          'test/unit/**/*.coffee'
        ]
      }
    },

    usebanner : {
      copyright : {
        options : {
          position  : 'top',
          banner    : copyright,
          linebreak : true
        },
        files   : {
          src : [
            'lib/**/*.js'
          ]
        }
      }
    }
  });
};