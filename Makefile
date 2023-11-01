clean: clean-npm
	echo "Done"

clean-npm:
	rm -rf node_modules

bundle: clean
	rm -f project.zip && zip -r project.zip package.json src test circuits artifacts Makefile
