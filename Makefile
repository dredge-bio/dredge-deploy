
DREDGE_WWW          ?= /run/user/1001/gvfs/smb-share:server=web.bio.unc.edu,share=dredge
DREDGE_REPOSITORY   ?= /home/ptgolden/Code/projects/dredge
DREDGE_SHARED_DATA  ?= /home/ptgolden/Dropbox/dredge

DREDGE_VERSION      := dredge-$(subst v,,$(shell git --git-dir $(DREDGE_REPOSITORY)/.git describe --tags))
DREDGE_CODE         := staging/$(DREDGE_VERSION)
DREDGE_ZIP          := $(DREDGE_REPOSITORY)/dist/$(DREDGE_VERSION).zip

PROJECTS            := $(shell find $(DREDGE_SHARED_DATA) -maxdepth 1 -type d -name project_*)

RSYNC_FLAGS         := -rtv --progress
PROJECT_RSYNC_FLAGS := --delete --exclude extra

ifndef UPLOAD_PAIRWISE_FILES
	PROJECT_RSYNC_FLAGS += --exclude *pairwise*
endif

.PHONY: all clean help homepage $(PROJECTS)

help:
	@echo
	@echo "  Upload all projects in a shared directory to a Web server."
	@echo
	@echo "  Usage: make upload"
	@echo
	@echo "  Any folders in the shared directory starting with \"project_\" will be"
	@echo "  treated as a project to be uploaded. On the server, they will be copied"
	@echo "  without the project_prefix"
	@echo
	@echo "  By default, projects will be searched for in the directory:"
	@echo "   - $(DREDGE_SHARED_DATA)"
	@echo
	@echo "  They will be uploaded to:"
	@echo "   - $(DREDGE_WWW)"
	@echo
	@echo "  They will be deployed with the latest tag in the git repository:"
	@echo "   - $(DREDGE_REPOSITORY)"
	@echo
	@echo "  These can be configured with the following environment variables, respectively:"
	@echo "   - DREDGE_SHARED_DATA"
	@echo "   - DREDGE_WWW"
	@echo "   - DREDGE_REPOSITORY"
	@echo
	@echo "  For example, to upload to the directory /var/lib/www/dredge, run the command:"
	@echo "   - DREDGE_WWW=/var/lib/www/dredge make upload"
	@echo
	@echo "  To save time, by default, the folder of pairwise comparisons are not uploaded."
	@echo "  To change, this setting, set the environment variable UPLOAD_PAIRWISE_FILES"
	@echo

upload: $(PROJECTS) homepage

clean:
	rm -rf staging

$(DREDGE_ZIP):
	cd $(DREDGE_REPOSITORY) && make zip

$(DREDGE_CODE): $(DREDGE_ZIP)
	unzip -d staging $<
	touch $@

homepage: index.html $(DREDGE_ZIP)
	cp $< $<.tmp
	sed -i -e 's/%%UPDATED%%/$(shell date +'%B %Y')/' $<.tmp
	sed -i -e 's/%%VERSION%%/$(DREDGE_VERSION)/g' $<.tmp
	rsync $(RSYNC_FLAGS) $<.tmp $(DREDGE_WWW)/$<
	rm -f $<.tmp
	rsync $(RSYNC_FLAGS) dredge*.png $(DREDGE_WWW)/
	rsync $(RSYNC_FLAGS) $(DREDGE_ZIP) $(DREDGE_WWW)

$(PROJECTS): $(DREDGE_SHARED_DATA)/project_%: $(DREDGE_CODE)
	rsync $(RSYNC_FLAGS) $(PROJECT_RSYNC_FLAGS) $@/ $(DREDGE_WWW)/$*
	rsync $(RSYNC_FLAGS) $</ $(DREDGE_WWW)/$*
	rsync $(RSYNC_FLAGS) $(DREDGE_ZIP) $(DREDGE_WWW)/$*
