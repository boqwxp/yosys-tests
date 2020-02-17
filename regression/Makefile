PYTHON_EXECUTABLE := $(shell if python3 -c ""; then echo "python3"; else echo "python"; fi)

all::
	@echo 'Force recreate run-test.mk..'
	@rm -rf run-test.mk

run-test.mk: ../generate.py
	@$(PYTHON_EXECUTABLE) ../generate.py > run-test.mk

include run-test.mk

clean::
	@rm -rf run-test.mk
	@echo 'Cleaning run-test.mk..'

.PHONY: all clean
