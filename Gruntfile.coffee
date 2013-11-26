path = require("path")
fs = require("fs")

module.exports = (grunt) ->

	# External tasks
	@registerTask(
		"default"
		"Default task that runs the production build"
		[
			"dist"
		]
	)

	@registerTask(
		"dist"
		"Produces the production files"
		[
			"test"
			"build"
			"assets-dist"
			"assemble:demos"
			"assemble:demos_min"
			"htmlcompressor"
		]
	)

	@registerTask(
		"debug"
		"Produces unminified files"
		[
			"build"
			"assemble:demos"
		]
	)

	@registerTask(
		"build"
		"Run full build."
		[
			"clean:dist"
			"assets"
			"js"
			"css"
		]
	)

	@registerTask(
		"deploy"
		"Build and deploy artifacts to wet-boew-dist"
		[
			"dist"
			"assemble:demos"
			"assemble:demos_min"
			"htmlcompressor"
			"copy:deploy"
			"gh-pages"
		]
	)

	@registerTask(
		"test-mocha"
		"Full build for running tests locally with Grunt Mocha"
		[
			"pre-mocha"
			"mocha"
		]
	)

	@registerTask(
		"saucelabs"
		"Full build for running tests on SauceLabs. Currently only for Travis builds"
		[
			"pre-mocha"
			"saucelabs-mocha"
		]
	)

	@registerTask(
		"init"
		"Only needed when the repo is first cloned"
		[
			"modernizr"
		]
	)

	#Internal task groups
	@registerTask(
		"js"
		"INTERNAL: Copies all third party JS to the dist folder"
		[
			"copy:polyfills"
			"copy:other"
			"copy:deps"
			"copy:jsAssets"
			"copy:jsDemoPlugins"
			"copy:jsDemoPolyfills"
			"copy:jsDemoOther"
			"i18n"
			"concat:core"
			"concat:coreIE8"
			"concat:pluginsIE8"
			"concat:i18n"
			"uglify"
		]
	)

	@registerTask(
		"css"
		"INTERNAL: Compiles Sass and copies third party CSS to the dist folder"
		[
			"sprites"
			"sass"
			"autoprefixer"
			"concat:css"
			"cssmin"
			"copy:sprites"
		]
	)

	@registerTask(
		"assets-dist"
		"INTERNAL: Process non-CSS/JS assets to dist"
		[
			"copy:assets_min"
			"copy:misc_min"
		]
	)

	@registerTask(
		"assets"
		"INTERNAL: Process non-CSS/JS assets to dist"
		[
			"copy:misc"
			"copy:themeAssets"
			"copy:bootstrap"
		]
	)

	@registerTask(
		"test"
		"INTERNAL: Runs testing tasks except for SauceLabs testing"
		[
			"jshint"
		]
	)

	@registerTask(
		"pre-mocha"
		"INTERNAL: prepare for running Mocha unit tests"
		[
			"build"
			"assets-dist"
			"assemble:demos_min"
			"connect:test"
		]
	)

	grunt.util.linefeed = "\n"
	# Project configuration.
	grunt.initConfig

		# Metadata.
		pkg: grunt.file.readJSON("package.json")
		banner: "/*! Web Experience Toolkit (WET) / Boîte à outils de l'expérience Web (BOEW)\nwet-boew.github.io/wet-boew/License-en.html / wet-boew.github.io/wet-boew/Licence-fr.html\n" +
				" - v<%= pkg.version %> - " + "<%= grunt.template.today(\"yyyy-mm-dd\") %>\n*/\n"
		modernizrBanner: "/*! Modernizr (Custom Build) | MIT & BSD */\n"

		# Task configuration.
		concat:
			options:
				banner: "<%= banner %><%= modernizrBanner %>"

			core:
				options:
					stripBanners: false
				src: [
					"lib/modernizr/modernizr-custom.js"
					"src/core/vapour.js"
					"src/core/helpers.js"
					"src/plugins/**/*.js"
					"!src/plugins/**/test.js"
					"!src/plugins/**/assets/*.js"
					"!src/plugins/**/demo/*.js"
				]
				dest: "dist/unmin/js/wet-boew.js"

			coreIE8:
				options:
					stripBanners: false
				src: [
					"lib/modernizr/modernizr-custom.js"
					"lib/respond/respond.src.js"
					"lib/excanvas/excanvas.js"
					"lib/html5shiv/dist/html5shiv.js"
					"lib/selectivizr/selectivizr.js"
					"src/core/vapour.js"
					"!src/plugins/**/test.js"
					"!src/plugins/**/assets/*.js"
					"!src/plugins/**/demo/*.js"
				]
				dest: "dist/unmin/js/ie8-wet-boew.js"

			pluginsIE8:
				options:
					banner: "<%= banner %>"
					stripBanners: false
				src: [
					"src/core/helpers.js"
					"src/plugins/**/*.js"
					"!src/plugins/**/test.js"
					"!src/plugins/**/assets/*.js"
					"!src/plugins/**/demo/*.js"
				]
				dest: "dist/unmin/js/ie8-wet-boew2.js"

			i18n:
				options:
					process: ( src, filepath ) ->
						lang = filepath.replace "dist/unmin/js/i18n/", ""
						# jQuery validation uses an underscore for locals
						lang = lang.replace "_", "-"
						validationPath = "lib/jquery.validation/localization/"

						# Check and append message file
						messagesPath = validationPath + "messages_" + lang
						messages = if grunt.file.exists messagesPath then grunt.file.read( messagesPath ) else ""

						# Check and append method file
						methodsPath = validationPath + "methods_" + lang
						methods = if grunt.file.exists methodsPath then grunt.file.read( methodsPath ) else ""

						if methods != "" or messages != ""
							src += "\nvapour.doc.one( \"formLanguages.wb\", function() {\n"
							src += messages
							src += "\n"
							src += methods
							src += "\n});"

						return src

				cwd: "dist/unmin/js/i18n"
				src: [
					"*.js"
					"!*.min.js"
				]
				dest: "dist/unmin/js/i18n"
				expand: true

			css:
				options:
					banner: ""
				files:
					"dist/unmin/css/wet-boew.css": [
						"lib/bootstrap/dist/css/bootstrap.css"
						"dist/unmin/css/wet-boew.css"
					]

		# Builds the demos
		assemble:
			options:
				prettify:
					indent: 2
				marked:
					sanitize: false
				production: false
				data: "site/data/**/*.{yml,json}"
				helpers: "site/helpers/helper-*.js"
				layoutdir: "site/layouts"
				partials: "site/includes/**/*.hbs"
				layout: "default.hbs"

			demos:
				options:
					environment:
						root: "/v4.0-ci/unmin"
					assets: "dist/unmin"
				files: [
						expand: true
						cwd: "src"
						src: "*.hbs"
						dest: "dist/unmin"
					,
						expand: true
						cwd: "src/plugins"
						src: "**/*.hbs"
						dest: "dist/unmin/demos"
					,
						expand: true
						cwd: "src/polyfills"
						src: "**/*.hbs"
						dest: "dist/unmin/demos"
					,
						expand: true
						cwd: "src/other"
						src: "**/*.hbs"
						dest: "dist/unmin/demos"
					,
						cwd: "site/pages/ajax"
						src: "*.hbs"
						dest: "dist/unmin/ajax"
						expand: true
						flatten: true
				]

			demos_min:
				options:
					environment:
						suffix: ".min"
						root: "/v4.0-ci"
					assets: "dist"
				files: [
						expand: true
						cwd: "src"
						src: "*.hbs"
						dest: "dist"
					,
						expand: true
						cwd: "src/plugins"
						src: "**/*.hbs"
						dest: "dist/demos"
					,
						expand: true
						cwd: "src/polyfills"
						src: "**/*.hbs"
						dest: "dist/demos"
					,
						expand: true
						cwd: "src/other"
						src: "**/*.hbs"
						dest: "dist/demos"
					,
						cwd: "site/pages/ajax"
						src: "*.hbs"
						dest: "dist/ajax"
						expand: true
						flatten: true
				]

		#Generate the sprites include stylesheets
		sprites:
			share:
				src: [
					"src/plugins/share/sprites/*.png"
					"!src/plugins/share/sprites/sprites_*.png"
				]
				css: "src/plugins/share/_sprites.scss"
				map: "src/plugins/assets/sprites_share.png"
				output: "scss"
			tables:
				src: [
					"src/plugins/tables/sprites/*.png"
					"!src/plugins/tables/sprites/sprites_*.png"
				]
				css: "src/plugins/tables/_sprites.scss"
				map: "src/plugins/assets/sprites_tables.png"
				output: "scss"

		# Compiles the Sass files
		sass:
			all:
				expand: true
				cwd: "src/base"
				src: [
					"**/*.scss"
					"!**/_*.scss"
					"!**/demo/*.scss"
				]
				dest: "dist/unmin/css/"
				ext: ".css"

			theme:
				expand: true
				cwd: "theme/sass"
				src: [
					"**/*.scss"
					"!**/_*.scss"
				]
				dest: "dist/unmin/css/"
				ext: ".css"

			polyfills:
				expand: true
				cwd: "src/polyfills"
				src: [
					"**/*.scss"
					"!**/*-base.scss"
					"!**/*-ie8.scss"
					"!**/*-noscript.scss"
					"!**/demo/*.scss"
				]
				dest: "dist/unmin/css/polyfills/"
				ext: ".css"
				flatten: true

			other:
				expand: true
				cwd: "src/other"
				src: [
					"**/*.scss"
					"!**/*base.scss"
					"!**/demo/*.scss"
				]
				dest: "dist/unmin/css/other/"
				ext: ".css"
				flatten: true

			demo_plugins:
				expand: true
				cwd: "src/plugins"
				src: "**/demo/*.scss"
				dest: "dist/unmin/demos/"
				ext: ".css"

			demo_polyfills:
				expand: true
				cwd: "src/polyfills"
				src: "**/demo/*.scss"
				dest: "dist/unmin/demos/"
				ext: ".css"

			demo_other:
				expand: true
				cwd: "src/other"
				src: "**/demo/*.scss"
				dest: "dist/unmin/demos/"
				ext: ".css"

		autoprefixer:
			options:
				browsers: [
					"last 2 versions"
					"ff >= 17"
					"opera 12.1"
					"bb >= 7"
					"android >= 2.3"
					"ie >= 8"
					"ios 5"
				]

			all:
				cwd: "dist/unmin/css"
				src: [
					"**/*.css"
					"!**/polyfills/**/*.css"
					"!**/other/**/*.css"
					"!**/*.min.css"
				]
				dest: "dist/unmin/css"
				expand: true
				flatten: true

			polyfills:
				cwd: "dist/unmin/css/polyfills"
				src: [
					"**/*.css"
					"!**/*.min.css"
				]
				dest: "dist/unmin/css/polyfills/"
				expand: true

			other:
				cwd: "dist/unmin/css/other"
				src: [
					"**/*.css"
					"!**/*.min.css"
				]
				dest: "dist/unmin/css/other/"
				expand: true

		# Minify
		uglify:
			polyfills:
				options:
					preserveComments: (uglify,comment) ->
						return comment.value.match(/^!/i)
				expand: true
				cwd: "dist/unmin/js/polyfills/"
				src: ["*.js"]
				dest: "dist/js/polyfills/"
				ext: ".min.js"

			other:
				options:
					preserveComments: (uglify,comment) ->
						return comment.value.match(/^!/i)
				expand: true
				cwd: "dist/unmin/js/other/"
				src: ["*.js"]
				dest: "dist/js/other/"
				ext: ".min.js"

			demo:
				options:
					banner: "<%= banner %>"
					preserveComments: (uglify,comment) ->
						return comment.value.match(/^!/i)
				expand: true
				cwd: "dist/unmin/demos/"
				src: ["**/demo/*.js"]
				dest: "dist/demos/"
				ext: ".min.js"

			core:
				options:
					preserveComments: (uglify,comment) ->
						return comment.value.match(/^!/i)
				cwd: "dist/unmin/js/"
				src: [ "*wet-boew*.js" ]
				dest: "dist/js/"
				ext: ".min.js"
				expand: true

			i18n:
				options:
					banner: "<%= banner %>"
				expand: true
				cwd: "dist/unmin/js/i18n"
				src: ["**/*.js"]
				dest: "dist/js/i18n"
				ext: ".min.js"

			deps:
				options:
					preserveComments: "some"
				expand: true
				cwd: "dist/unmin/js/deps"
				src: ["*.js"]
				dest: "dist/js/deps/"
				rename: (destBase, destPath) ->
					return destBase + destPath.replace(/\.js$/, ".min.js")

		cssmin:
			options:
				banner: "@charset \"utf-8\";\n<%= banner %>"
			dist:
				expand: true
				cwd: "dist/unmin/css"
				src: [
					"**/*.css"
					"!**/*.min.css"
				]
				dest: "dist/css"
				ext: ".min.css"

			demo:
				expand: true
				cwd: "dist/unmin/demos/"
				src: [
					"**/demo/*.css"
					"!**/demo/*.min.css"
				]
				dest: "dist/demos/"
				ext: ".min.css"

		htmlcompressor:
			options:
				type: "html"
			all:
				cwd: "dist"
				src: [
					"**/*.html"
					"!unmin/**/*.html"
				]
				dest: "dist"
				expand: true

		modernizr:
			devFile: "lib/modernizr/modernizr-custom.js"
			outputFile: "lib/modernizr/modernizr-custom.js"
			extra:
				shiv: false
				printshiv: false
				load: true
				mq: true
				css3: true
				input: true
				inputtypes: true
				svg: true
				html5: false
				cssclasses: true
				csstransitions: true
				fontface: true
				backgroundsize: true
				borderimage: true
			extensibility:
				addtest: false
				prefixed: false
				teststyles: true
				testprops: true
				testallprops: true
				hasevents: true
				prefixes: true
				domprefixes: true
			tests: [
				"elem_details"
				"elem_progress_meter"
			]
			parseFiles: false
			matchCommunityTests: false

		copy:
			bootstrap:
				cwd: "lib/bootstrap/fonts"
				src: "*.*"
				dest: "dist/unmin/fonts"
				expand: true
				flatten: true

			misc:
				cwd: "src/plugins"
				src: [
					"**/*.*"
					"!**/*.js"
					"!**/*.scss"
					"!**/*.hbs"
					"!**/assets/*"
				]
				dest: "dist/unmin/demos"
				expand: true

			polyfills:
				cwd: "src/polyfills"
				src: "**/*.js"
				dest: "dist/unmin/js/polyfills"
				expand: true
				flatten: true

			other:
				cwd: "src/other"
				src: "**/*.js"
				dest: "dist/unmin/js/other"
				expand: true
				flatten: true

			deps:
				cwd: "lib"
				src: [
					"jquery-pjax/jquery.pjax.js"
					"jquery.validation/jquery.validate.js"
					"jquery.validation/additional-methods.js"
					"magnific-popup/dist/jquery.magnific-popup.js"
					"google-code-prettify/src/*.js"
					"DataTables/media/js/jquery.dataTables.js"
				]
				dest: "dist/unmin/js/deps"
				expand: true
				flatten: true

			jsAssets:
				cwd: "src"
				src: [
					"plugins/**/assets/*"
					"polyfills/**/assets/*"
					"other/**/assets/*"
				]
				dest: "dist/unmin/assets"
				expand: true
				flatten: true

			jsDemoPlugins:
				cwd: "src/plugins"
				src: "**/demo/*.js"
				dest: "dist/unmin/demos/"
				expand: true

			jsDemoPolyfills:
				cwd: "src/polyfills"
				src: "**/demo/*.js"
				dest: "dist/unmin/demos/"
				expand: true

			jsDemoOther:
				cwd: "src/other"
				src: "**/demo/*.js"
				dest: "dist/unmin/demos/"
				expand: true

			sprites:
				cwd: "src/assets/"
				src: "*.*"
				dest: "dist/unmin/assets"
				expand: true
				flatten: true

			themeAssets:
				cwd: "theme/"
				src: "**/assets/*.*"
				dest: "dist/unmin"
				expand: true

			assets_min:
				cwd: "dist/unmin/"
				src: [
					"assets/*"
					"fonts/*"
					"js/assets/*"
					"!**/assets/*.js"
				]
				dest: "dist"
				expand: true

			misc_min:
				cwd: "src/plugins"
				src: [
					"**/*.*"
					"!**/*.js"
					"!**/*.scss"
					"!**/*.hbs"
					"!**/assets/*"
				]
				dest: "dist/demos"
				expand: true

			deploy:
				src: [
					"*.txt"
					"README.md"
				]
				dest: "dist"
				expand: true

		clean:
			dist: ["dist", "src/base/partials/*sprites*"]

		watch:
			lib_test:
				files: "<%= jshint.lib_test.src %>"
				tasks: "jshint:lib_test"

			source:
				files: "src/**.*"
				tasks: "dist"
				options:
					interval: 5007
					livereload: true

			demos:
				files: [
					"**/*.hbs"
				]
				tasks: [
					"assemble"
				]
				options:
					interval: 5007
					livereload: true

		jshint:
			options:
				jshintrc: ".jshintrc"

			lib_test:
				src: [
					"src/**/*.js"
					"theme/**/*.js"
					"test/**/*.js"
					"tasks/*.js"
				]

		connect:
			options:
				port: 8000

			server:
				options:
					base: "dist"
					middleware: (connect, options) ->
						middlewares = []
						middlewares.push(connect.compress(
							filter: (req, res) ->
								/json|text|javascript|dart|image\/svg\+xml|application\/x-font-ttf|application\/vnd\.ms-opentype|application\/vnd\.ms-fontobject/.test(res.getHeader('Content-Type'))
						))
						middlewares.push(connect.static(options.base));
						middlewares

			test:
				options:
					base: "."
					middleware: (connect, options) ->
						middlewares = []

						mochascript = (req, res, next) ->
							url = req._parsedUrl.pathname

							# Skip to the static middleware if it's an index file or not HTML
							if /index|mobmenu[-]?\w*\.html/.test( url ) or not /\.html/.test( url )
								return next()

							dir = url.substring( 0, url.lastIndexOf( "/" ) + 1 )

							# Test to see if the plugin or polyfill has a test file
							plugins = dir.replace("/dist/demos/", "src/plugins/") + "test.js"

							polyfills = dir.replace("/dist/demos/", "src/polyfills/") + "test.js"

							testFile = if fs.existsSync( plugins ) then plugins else if fs.existsSync( polyfills ) then polyfills else ""

							if testFile != ""

								result = fs.readFileSync( __dirname + url, { encoding: "utf-8" } )

								# Append mocha content to the response above the footer
								result = result.replace( "</main>", "<div class='row' id='mocha'></div></main>" )

								mochaPath = path.dirname( require.resolve( "mocha" ) )

								testHtml = "<link src='/" + path.relative(__dirname, mochaPath) + "/mocha.css' />"
								testHtml += "<script src='/" + path.relative(__dirname, mochaPath) + "/mocha.js'></script>"

								# Append ExpectJS script
								testHtml += "<script src='/" + path.relative(__dirname, require.resolve( "expect.js" ) ) + "'></script>"

								# Append Sinon scripts
								testHtml += "<script src='/" + path.dirname( path.relative(__dirname, require.resolve( "sinon" ) ) ) + "/../pkg/sinon.js'></script>"
								testHtml += "<!--[if lt IE 9]><script src='/" + path.dirname( path.relative(__dirname, require.resolve( "sinon" ) ) ) + "/../pkg/sinon-ie.js'></script><![endif]-->"

								testHtml += "<script>mocha.setup( 'bdd' ); vapour.doc.on( 'ready', function() { mocha.run(); } );</script>"

								testHtml += "<script src='/" + testFile + "'></script>"

								testHtml += "</body>"

								result = result.replace( "</body>", testHtml )

								res.end( result )
							else
								# No test files found, skipping
								return next()

						middlewares.push mochascript

						# Serve static files.
						middlewares.push connect.static( options.base )

						middlewares

		i18n:
			options:
				template: "src/i18n/base.js"
				csv: "src/i18n/i18n.csv"
				dest: "dist/unmin/js/i18n/"

		mocha:
			all:
				options:
					reporter: "Spec"
					urls: grunt.file.expand(
						filter: ( src ) ->
							src = path.dirname( src ).replace( /\\/g , "/" ) #" This is to escape a Sublime text regex issue in the replace
							return fs.existsSync( src + "/test.js" )
						"src/plugins/**/*.hbs"
						"src/polyfills/**/*.hbs"
					).map( ( src ) ->
						src = src.replace( /\\/g , "/" ) #" This is to escape a Sublime text regex issue in the replace
						src = src.replace( "src/", "dist/")
						src = src.replace( "plugins/", "demos/" )
						src = src.replace( "polyfills/", "demos/" )
						src = src.replace( ".hbs", ".html" )
						return "http://localhost:8000/" + src
					)

		"saucelabs-mocha":
			all:
				options:
					urls: grunt.file.expand(
						filter: ( src ) ->
							src = path.dirname( src ).replace( /\\/g , "/" ) #" This is to escape a Sublime text regex issue in the replace
							return fs.existsSync( src + "/test.js" )
						"src/plugins/**/*.hbs"
						"src/polyfills/**/*.hbs"
					).map( ( src ) ->
						src = src.replace( /\\/g , "/" ) #" This is to escape a Sublime text regex issue in the replace
						src = src.replace( "src/", "dist/")
						src = src.replace( "plugins/", "demos/" )
						src = src.replace( "polyfills/", "demos/" )
						src = src.replace( ".hbs", ".html" )
						return "http://localhost:8000/" + src
					)
					tunnelTimeout: 5
					build: process.env.TRAVIS_BUILD_NUMBER
					concurrency: 3
					browsers: grunt.file.readJSON "browsers.json"
					testname: "WET-BOEW Travis Build #{process.env.TRAVIS_BUILD_NUMBER}"
					tags: [
						process.env.TRAVIS_BRANCH,
						process.env.TRAVIS_COMMIT
					]

		"gh-pages":
			options:
				repo: "https://" + process.env.GH_TOKEN + "@github.com/wet-boew/wet-boew-dist.git"
				branch: process.env.build_branch
				clone: "wet-boew-dist"
				message: "Travis build " + process.env.TRAVIS_BUILD_NUMBER
				silent: true
				base: "dist"
			src: [
				"**/*.*"
			]


	# These plugins provide necessary tasks.
	@loadNpmTasks "assemble"
	@loadNpmTasks "grunt-autoprefixer"
	@loadNpmTasks "grunt-contrib-clean"
	@loadNpmTasks "grunt-contrib-concat"
	@loadNpmTasks "grunt-contrib-connect"
	@loadNpmTasks "grunt-contrib-copy"
	@loadNpmTasks "grunt-contrib-cssmin"
	@loadNpmTasks "grunt-contrib-jshint"
	@loadNpmTasks "grunt-contrib-uglify"
	@loadNpmTasks "grunt-contrib-watch"
	@loadNpmTasks "grunt-gh-pages"
	@loadNpmTasks "grunt-htmlcompressor"
	@loadNpmTasks "grunt-imagine"
	@loadNpmTasks "grunt-mocha"
	@loadNpmTasks "grunt-modernizr"
	@loadNpmTasks "grunt-sass"
	@loadNpmTasks "grunt-saucelabs"

	# Load custom grunt tasks form the tasks directory
	@loadTasks "tasks"

	@