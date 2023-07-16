.PHONY: docs test style lint package

lint: style
	@python3 -m pylint --rcfile=pylint3.cfg \
		--reports=no trlc trlc*.py

style:
	@python3 -m pycodestyle trlc trlc*.py

test:
	coverage run -p --rcfile=tests/coverage.cfg --branch --data-file tests/.coverage ./trlc-lrm-generator.py
	make -C tests -B -j6 fast

test-all:
	coverage run -p --rcfile=tests/coverage.cfg --branch --data-file tests/.coverage ./trlc-lrm-generator.py
	make -C tests -B -j6 all

docs:
	rm -rf docs
	mkdir docs
	@util/rebuild_old_lrm.sh
	@python3 trlc-lrm-generator.py --tag
	@python3 -m util.mk_ast_hierarchy | \
		dot -Tsvg > docs/ast_hierarchy.svg
	@python3 -m util.mk_parser_hierarchy | \
		dot -Tsvg > docs/parser_hierarchy.svg
	sphinx-build -c sphinx -b html . docs

docs-and-commit: docs
	git add docs
	git commit -m "Re-generate documentation for release."

package:
	@git clean -xdf
	@python3 setup.py sdist bdist_wheel
	@python3 setup.py bdist_wheel -p linux_x86_64
	@python3 setup.py bdist_wheel -p macosx_x86_64

upload_main: package
	python3 -m twine upload --repository pypi dist/*

remove_dev:
	python3 -m util.release

github_release:
	git push
	python3 -m util.github_release

bump:
	python3 -m util.bump_version_post_release

full_release:
	make remove_dev
	make docs-and-commit
	git push
	make package
	make upload_main
	make github_release
	make bump
	git push

requirements.lobster: language-reference-manual/lobster-trlc.conf language-reference-manual/lrm.rsl language-reference-manual/lrm.trlc
	lobster-trlc \
		--config-file=language-reference-manual/lobster-trlc.conf \
		--out requirements.lobster \
		language-reference-manual

code.lobster: $(wildcard trlc/*.py)
	lobster-python --out code.lobster trlc

report.lobster: lobster.conf requirements.lobster code.lobster
	lobster-report \
		--lobster-config=lobster.conf \
		--out=report.lobster
	lobster-online-report report.lobster

tracing.html: report.lobster
	lobster-html-report report.lobster --out=tracing.html
	lobster-ci-report report.lobster
