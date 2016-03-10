// This example requires using node's `path` module
var path = require('path');

module.exports = function(grunt) {
    var rokuIP = grunt.option('address');
    var rokuUser = grunt.option('user');
    var rokuPassword = grunt.option('pwd');
    grunt.initConfig({

        zip: {
            'using-router': {
                // `router` receives the path from grunt (e.g. js/main.js)
                // The path it returns is what the file contents are saved as (e.g. all/main.js)
                router: function (filepath) {
                    // Route each file to all/{{filename}}
                    var filename = path.basename(filepath);
                    if (filepath.startsWith("source"))
                        return 'source/' + filename;
                    else if (filepath.startsWith("manifest"))
                        return filename
                    else return 'images/' + filename;
                },
                
                src: ['manifest',
                    'source/appMain.brs',
                    'images/*',
                    'source/IQ.brs'],
                dest: 'out/ooyala-iq-sample.zip'
            }


        },

        shell: {
            options: {
                stderr: false
            },
            target: {
                command: 'curl -S -F "mysubmit=Install" -F "archive=@out/ooyala-iq-sample.zip" --digest --user '+rokuUser +':'+rokuPassword+ ' -F "passwd='+ rokuPassword+'" http://'+ rokuIP+ '/plugin_install'
            }
        }

    })
    grunt.loadNpmTasks('grunt-zip');
    grunt.loadNpmTasks('grunt-shell');
    grunt.registerTask('default', ['zip','shell'])
}
