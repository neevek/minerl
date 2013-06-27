NAME = minerl
INSTALLBIN = /usr/local/bin

TO_INST_PM = lib/Minerl/BaseObject.pm \
	lib/Minerl/Formatter/Markdown.pm \
	lib/Minerl/Formatter/Perl.pm \
	lib/Minerl/Page.pm \
	lib/Minerl/PageManager.pm \
	lib/Minerl/Template.pm \
	lib/Minerl/TemplateManager.pm \
	lib/Minerl/Util.pm \
	lib/minerl.pm \
	minerl.pl

default: test-dependencies ${TO_INST_PM}
	echo "#!/usr/bin/perl -w" > ${NAME}
	echo "use strict;" >> ${NAME};
	echo "use warnings;" >> ${NAME};
	cat ${TO_INST_PM} >> ${NAME}
	chmod +x ${NAME}

install:
	cp ${NAME} ${INSTALLBIN}

test: 
	prove -Ilib t/

clean:
	rm ${NAME} 

test-dependencies:
	test -f test-dependencies.pl && perl test-dependencies.pl
