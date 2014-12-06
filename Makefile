APP=hash_tables
NODE=$(APP)@localhost

DIALYZER_OPTS=-Werror_handling -Wrace_conditions -Wunmatched_returns

DEPENDED_APPS=crypto,xmerl,inets

all: init compile xref eunit edoc dialyze

create-app:
	if [ -f src/*.app.src ]; then \
		echo "Application arleary was initialized."; \
	else \
		git init; \
		./rebar create template=dwapp appid=$(APP); \
		make init; \
		echo "========================================"; \
		echo "Please register a git remote repository."; \
		echo "Hint: git remote add origin ssh://..."; \
	fi \

init:
	@./rebar get-deps compile

compile:
	@./rebar compile skip_deps=true

xref:
	@./rebar xref skip_deps=true

clean:
	@./rebar clean skip_deps=true

eunit:
	@./rebar eunit skip_deps=true

edoc:
	@./rebar doc skip_deps=true

start: compile
	erl -sname $(NODE) -pz ebin $(shell find deps -type d -name ebin 2>/dev/null) -s reloader \
	  -eval 'erlang:display(application:ensure_all_started($(APP))).'


.dialyzer.plt:
	touch .dialyzer.plt
	dialyzer --build_plt --plt .dialyzer.plt --apps erts kernel stdlib compiler $(shell echo $(DEPENDED_APPS) | sed -e 's/,/ /g') \
		-r $(shell find deps -type d -name ebin 2>/dev/null | grep -Ev '^deps/((meck|reloader|edown|eunit)|.*/deps/)')

dialyze: .dialyzer.plt compile
	dialyzer --plt .dialyzer.plt -r ebin $(DIALYZER_OPTS)
