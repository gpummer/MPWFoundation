# $Id: GNUmakefile,v 1.11 2004/12/08 21:20:43 marcel Exp $

#include $(GNUSTEP_MAKEFILES)/common.make

FRAMEWORK_NAME = MPWFoundation

GNUSTEP_LOCAL_ADDITIONAL_MAKEFILES=base.make
GNUSTEP_BUILD_DIR = ~/Build/MPWFoundation

include $(GNUSTEP_MAKEFILES)/common.make

libMPWFoundation_DLL_DEF = MPWFoundation.def

LIBRARY_NAME = libMPWFoundation
CC = clang



MPWFoundation_HEADER_FILES = \
	AccessorMacros.h		\
	CodingAdditions.h		\
	DebugMacros.h			\
	FIFO.h				\
	MPWASCII85Stream.h		\
	MPWAssociation.h		\
	MPWAsyncProxy.h			\
	MPWByteStream.h			\
	MPWEnumFilter.h			\
	MPWEnumSelectFilter.h		\
	MPWEnumeratorBase.h		\
	MPWEnumeratorEnumerator.h	\
	MPWEnumeratorSource.h		\
	MPWFakedReturnMethodSignature.h	\
	MPWFilterStream.h		\
	MPWFlattenStream.h		\
	MPWFoundation.h			\
	MPWHierarchicalStream.h		\
	MPWIgnoreTrampoline.h		\
	MPWJetStream.h			\
	MPWLZWStream.h			\
	MPWMsgExpression.h		\
	MPWObject.h			\
	MPWObjectReference.h			\
	MPWObjectCache.h		\
	MPWPSByteStream.h		\
	MPWParallelStream.h		\
	MPWPoint.h			\
	MPWPropertyListStream.h		\
	MPWRealArray.h			\
	MPWRect.h			\
	MPWRuntimeAdditions.h		\
	MPWScanner.h			\
	MPWStream.h			\
	MPWSubData.h			\
	MPWTrampoline.h			\
	MPWUShortArray.h		\
	MPWUniqueString.h		\
	NSArrayFiltering.h		\
	NSArrayFilters.h		\
	NSBundleConveniences.h		\
	NSCaseInsensitiveUniqueString.h	\
	NSConditionLockSem.h		\
	NSDictAdditions.h		\
	NSEnumFilter.h			\
	NSEnumObjectFilter.h		\
	NSEnumeratorFiltering.h		\
	NSInvocationAdditions.h		\
	NSInvocationAdditions_lookup.h	\
	NSNil.h				\
	NSObjectAdditions.h		\
	NSObjectFiltering.h		\
	NSObjectInterThreadMessaging.h	\
	NSRectAdditions.h		\
	NSSelectEnumerator.h		\
	NSStringAdditions.h		\
	NSThreadInterThreadMessaging.h	\

MPWFoundation_HEADER_FILES_INSTALL_DIR = /MPWFoundation


libMPWFoundation_OBJC_FILES = \
	Stores.subproj/MPWAbstractStore.m \


MPWFoundation_SUBPROJECTS = \
	Collections.subproj	\
	Streams.subproj		\
	Comm.subproj		\


LIBRARIES_DEPEND_UPON += -lgnustep-base 

# LDFLAGS += -L /C/GNUstep/System/Libraries/ix86/mingw32/gnu-gnu-gnu/ 
OBJCFLAGS += -Wno-import -I Classes/ 


libMPWFoundation_INCLUDE_DIRS += -I.headers -I. -I..

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
-include GNUmakefile.postamble

before-all ::
	
#	@$(MKDIRS) $(libMPWFoundation_HEADER_FILES_DIR)
#	cp *.h $(libMPWFoundation_HEADER_FILES_DIR)
#	cp Collections.subproj/*.h $(libMPWFoundation_HEADER_FILES_DIR)
#	cp Comm.subproj/*.h        $(libMPWFoundation_HEADER_FILES_DIR)
#	cp Streams.subproj/*.h     $(libMPWFoundation_HEADER_FILES_DIR)
#	cp Threading.subproj/*.h   $(libMPWFoundation_HEADER_FILES_DIR)

after-clean ::
	rm -rf .headers
