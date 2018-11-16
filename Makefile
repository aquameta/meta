EXTENSION = meta
EXTVERSION = 0.2.0
DATA = $(EXTENSION)--$(EXTVERSION).sql
PG_CONFIG = pg_config

$(EXTENSION)--$(EXTVERSION).sql: $(sort $(filter-out $(wildcard *--*.sql),$(wildcard *.sql)))
	cat $^ > $@

PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
