#include <cxxabi.h>
#include <dlfcn.h>
#include <cstdio>
#include <string>

#include "POSIXPrivate.h"
#include "WAVM/Inline/Assert.h"
#include "WAVM/Inline/Lock.h"
#include "WAVM/Platform/Diagnostics.h"
#include "WAVM/Platform/Mutex.h"

using namespace WAVM;
using namespace WAVM::Platform;

extern "C" const char* __asan_default_options()
{
	return "handle_segv=false:handle_sigbus=false:handle_sigfpe=false:replace_intrin=false";
}

static Mutex& getErrorReportingMutex()
{
	static Platform::Mutex mutex;
	return mutex;
}

void Platform::dumpErrorCallStack(Uptr numOmittedFramesFromTop)
{
	std::fprintf(stderr, "Call stack:\n");
	CallStack callStack = captureCallStack(numOmittedFramesFromTop);
	for(auto frame : callStack.stackFrames)
	{
		std::string frameDescription;
		if(!Platform::describeInstructionPointer(frame.ip, frameDescription))
		{ frameDescription = "<unknown function>"; }
		std::fprintf(stderr, "  %s\n", frameDescription.c_str());
	}
	std::fflush(stderr);
}

void Platform::handleFatalError(const char* messageFormat, va_list varArgs)
{
	Lock<Platform::Mutex> lock(getErrorReportingMutex());
	std::vfprintf(stderr, messageFormat, varArgs);
	std::fprintf(stderr, "\n");
	std::fflush(stderr);
	std::abort();
}

void Platform::handleAssertionFailure(const AssertMetadata& metadata)
{
	Lock<Platform::Mutex> lock(getErrorReportingMutex());
	std::fprintf(stderr,
				 "Assertion failed at %s(%u): %s\n",
				 metadata.file,
				 metadata.line,
				 metadata.condition);
	dumpErrorCallStack(2);
	std::fflush(stderr);
}

bool Platform::describeInstructionPointer(Uptr ip, std::string& outDescription)
{
#if WAVM_ENABLE_RUNTIME
	// Look up static symbol information for the address.
	Dl_info symbolInfo;
	if(dladdr((void*)(ip - 1), &symbolInfo))
	{
		wavmAssert(symbolInfo.dli_fname);
		outDescription = "host!";
		outDescription += symbolInfo.dli_fname;
		outDescription += '!';
		if(!symbolInfo.dli_sname) { outDescription += "<unknown>"; }
		else
		{
			char demangledBuffer[1024];
			const char* demangledSymbolName = symbolInfo.dli_sname;
			if(symbolInfo.dli_sname[0] == '_')
			{
				Uptr numDemangledChars = sizeof(demangledBuffer);
				I32 demangleStatus = 0;
				if(abi::__cxa_demangle(symbolInfo.dli_sname,
									   demangledBuffer,
									   (size_t*)&numDemangledChars,
									   &demangleStatus))
				{ demangledSymbolName = demangledBuffer; }
			}
			outDescription += demangledSymbolName;
			outDescription += '+';
			outDescription += std::to_string(ip - reinterpret_cast<Uptr>(symbolInfo.dli_saddr));
		}
		return true;
	}
#endif
	return false;
}
