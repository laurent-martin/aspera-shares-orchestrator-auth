DIR_TOP=./
DIR_GEN=$(DIR_TOP)generated/
DIR_PRIV=$(DIR_TOP)private/
DIR_SH_SRC=$(DIR_TOP)src/shell/
DIR_RB_SRC=$(DIR_TOP)src/ruby/
GNU_TAR=gtar
include $(DIR_GEN)config.make
all:: $(DIR_GEN)config.make $(DIR_GEN)special_shares_auth.json
# patch for Shares
SHARES_SCRIPTS=$(DIR_RB_SRC)special_shares_auth.rb $(DIR_RB_SRC)shares_patch_web.rb $(DIR_RB_SRC)shares_patch_api.rb $(DIR_SH_SRC)shares_patch.sh
# contains generated and downloaded files
$(DIR_GEN).exists:
	mkdir -p $(DIR_GEN)
	touch $@
export orch_url orch_user orch_pass orch_workflow saml_domain
$(DIR_GEN)special_shares_auth.json: $(DIR_GEN).exists $(DIR_SH_SRC)special_shares_auth.json.tmpl $(DIR_PRIV)config.sh
	envsubst < $(DIR_SH_SRC)special_shares_auth.json.tmpl > $(DIR_GEN)special_shares_auth.json
# generate make file macros from shell variables
$(DIR_GEN)config.make: $(DIR_GEN).exists $(DIR_PRIV)config.sh
	env -i bash -c ". $(DIR_PRIV)config.sh;set|grep '^[a-z]'" > $(DIR_GEN)config.make
$(DIR_PRIV)config.sh:
	mkdir -p $(DIR_PRIV)
	cp $(DIR_SH_SRC)config_tmpl.sh $(DIR_PRIV)config.sh.tmpl
	@echo "Please edit $(DIR_PRIV)config.sh.tmpl and rename it to $(DIR_PRIV)config.sh" && exit 1
template:
	sed -e 's/=.*/=_fill_here_/' $(DIR_PRIV)config.sh > $(DIR_SH_SRC)config_tmpl.sh
shares_download:
	ascli shares repo down /london-demo-restricted/aspera-test-dir-small/10MB.18 --transfer-info=@json:'{"wss":false}'
shares_upload:
	ascli shares repo upload 'faux:///test1?1k' --to-folder=/london-demo-restricted/Upload --transfer-info=@json:'{"wss":false}'
shares_deploy: $(SHARES_SCRIPTS) $(DIR_GEN)special_shares_auth.json
	scp $(SHARES_SCRIPTS) $(DIR_GEN)special_shares_auth.json $(shares_server):
	ssh $(shares_server) sudo bash -c "'chmod a+x shares_patch.sh && ./shares_patch.sh apply'"
shares_pack: $(SHARES_SCRIPTS) $(DIR_GEN)special_shares_auth.json
	chmod a+x $(DIR_SH_SRC)shares_patch.sh
	$(GNU_TAR) -czf $(DIR_GEN)shares_patch.tar.gz $(SHARES_SCRIPTS) $(DIR_GEN)special_shares_auth.json --transform 's,^.*/,,'
shares_pack_tmpl: $(SHARES_SCRIPTS)
	chmod a+x $(DIR_SH_SRC)shares_patch.sh
	$(GNU_TAR) -czf $(DIR_GEN)shares_patch_tmpl.tar.gz $(SHARES_SCRIPTS) $(DIR_SH_SRC)special_shares_auth.json.tmpl --transform 's,^.*/,,'
clean:
	rm -fr $(DIR_GEN)
