EXTENSION = meta
EXTVERSION = 0.5.0
DATA = $(EXTENSION)--$(EXTVERSION).sql
PG_CONFIG = pg_config

$(EXTENSION)--$(EXTVERSION).sql: $(sort $(filter-out $(wildcard *--*.sql),$(wildcard 0*.sql)))
	rm -f $@
	cat $^ > $@

PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
