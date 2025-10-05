TESTS := 	gpu \
			cpu \
			btree_mux

.PHONY: $(TESTS)

.PHONY: all
all: $(TESTS)

$(TESTS):
	@cd $@ && $(MAKE)

.PHONY: clean
clean:
	$(foreach TEST, $(TESTS), $(MAKE) -C $(TEST) clean;)
