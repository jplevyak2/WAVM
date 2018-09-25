#pragma once

#include <memory>
#include <string>
#include <vector>

#include "WAVM/IR/Types.h"
#include "WAVM/IR/Value.h"
#include "WAVM/Inline/Assert.h"
#include "WAVM/Inline/BasicTypes.h"
#include "WAVM/Platform/Diagnostics.h"

// Declare IR::Module to avoid including the definition.
namespace WAVM { namespace IR {
	struct Module;
}}

// Declare the different kinds of objects. They are only declared as incomplete struct types here,
// and Runtime clients will only handle opaque pointers to them.
#define DECLARE_OBJECT_TYPE(kindId, kindName, Type)                                                \
	struct Type;                                                                                   \
	RUNTIME_API Type* as##kindName(Object* object);                                                \
	RUNTIME_API Type* as##kindName##Nullable(Object* object);                                      \
	RUNTIME_API const Type* as##kindName(const Object* object);                                    \
	RUNTIME_API const Type* as##kindName##Nullable(const Object* object);                          \
	RUNTIME_API Object* asObject(Type* object);                                                    \
	RUNTIME_API const Object* asObject(const Type* object);                                        \
	template<> inline Type* as<Type>(Object * object) { return as##kindName(object); }             \
	template<> inline const Type* as<const Type>(const Object* object)                             \
	{                                                                                              \
		return as##kindName(object);                                                               \
	}

namespace WAVM { namespace Runtime {

	struct Object;
	
	// Tests whether an object is of the given type.
	RUNTIME_API bool isA(Object* object, const IR::ExternType& type);
	RUNTIME_API IR::ExternType getObjectType(Object* object);

	inline Object* asObject(Object* object) { return object; }
	inline const Object* asObject(const Object* object) { return object; }

	template<typename Type> Type* as(Object* object);
	template<typename Type> const Type* as(const Object* object);

	DECLARE_OBJECT_TYPE(ObjectKind::function, Function, FunctionInstance);
	DECLARE_OBJECT_TYPE(ObjectKind::table, Table, TableInstance);
	DECLARE_OBJECT_TYPE(ObjectKind::memory, Memory, MemoryInstance);
	DECLARE_OBJECT_TYPE(ObjectKind::global, Global, GlobalInstance);
	DECLARE_OBJECT_TYPE(ObjectKind::exceptionType, ExceptionType, ExceptionTypeInstance);
	DECLARE_OBJECT_TYPE(ObjectKind::moduleInstance, ModuleInstance, ModuleInstance);
	DECLARE_OBJECT_TYPE(ObjectKind::context, Context, Context);
	DECLARE_OBJECT_TYPE(ObjectKind::compartment, Compartment, Compartment);

	//
	// Garbage collection
	//

	// A GC root pointer.
	template<typename ObjectType> struct GCPointer
	{
		GCPointer() : value(nullptr) {}
		GCPointer(ObjectType* inValue)
		{
			value = inValue;
			if(value) { addGCRoot(asObject(value)); }
		}
		GCPointer(const GCPointer<ObjectType>& inCopy)
		{
			value = inCopy.value;
			if(value) { addGCRoot(asObject(value)); }
		}
		GCPointer(GCPointer<ObjectType>&& inMove)
		{
			value = inMove.value;
			inMove.value = nullptr;
		}
		~GCPointer()
		{
			if(value) { removeGCRoot(asObject(value)); }
		}

		void operator=(ObjectType* inValue)
		{
			if(value) { removeGCRoot(asObject(value)); }
			value = inValue;
			if(value) { addGCRoot(asObject(value)); }
		}
		void operator=(const GCPointer<ObjectType>& inCopy)
		{
			if(value) { removeGCRoot(asObject(value)); }
			value = inCopy.value;
			if(value) { addGCRoot(asObject(value)); }
		}
		void operator=(GCPointer<ObjectType>&& inMove)
		{
			if(value) { removeGCRoot(asObject(value)); }
			value = inMove.value;
			inMove.value = nullptr;
		}

		operator ObjectType*() const { return value; }
		ObjectType& operator*() const { return *value; }
		ObjectType* operator->() const { return value; }

	private:
		ObjectType* value;
	};

	// Increments the object's counter of root references.
	RUNTIME_API void addGCRoot(Object* object);

	// Decrements the object's counter of root referencers.
	RUNTIME_API void removeGCRoot(Object* object);

	// Frees any unreferenced objects owned by a compartment.
	RUNTIME_API void collectCompartmentGarbage(Compartment* compartment);

	// Clears the given GC root reference to a compartment, and collects garbage for it. Returns
	// true if the entire compartment was freed by the operation, or false if there are remaining
	// root references that can reach it.
	RUNTIME_API bool tryCollectCompartment(GCPointer<Compartment>&& compartment);

	//
	// Exceptions
	//

#define ENUM_INTRINSIC_EXCEPTION_TYPES(visit)                                                      \
	visit(outOfBoundsMemoryAccess, WAVM::IR::ValueType::anyref, WAVM::IR::ValueType::i64);         \
	visit(outOfBoundsTableAccess, WAVM::IR::ValueType::anyref, WAVM::IR::ValueType::i64);          \
	visit(outOfBoundsDataSegmentAccess,                                                            \
		  WAVM::IR::ValueType::anyref,                                                             \
		  WAVM::IR::ValueType::i64,                                                                \
		  WAVM::IR::ValueType::i64);                                                               \
	visit(outOfBoundsElemSegmentAccess,                                                            \
		  WAVM::IR::ValueType::anyref,                                                             \
		  WAVM::IR::ValueType::i64,                                                                \
		  WAVM::IR::ValueType::i64);                                                               \
	visit(stackOverflow);                                                                          \
	visit(integerDivideByZeroOrOverflow);                                                          \
	visit(invalidFloatOperation);                                                                  \
	visit(invokeSignatureMismatch);                                                                \
	visit(reachedUnreachable);                                                                     \
	visit(indirectCallSignatureMismatch);                                                          \
	visit(uninitializedTableElement, WAVM::IR::ValueType::anyref, WAVM::IR::ValueType::i64);       \
	visit(calledAbort);                                                                            \
	visit(calledUnimplementedIntrinsic);                                                           \
	visit(outOfMemory);                                                                            \
	visit(misalignedAtomicMemoryAccess, WAVM::IR::ValueType::i64);                                 \
	visit(invalidArgument);

	// Information about a runtime exception.
	struct Exception
	{
#define DECLARE_INTRINSIC_EXCEPTION_TYPE(name, ...)                                                \
	RUNTIME_API static ExceptionTypeInstance* name##Type;
		ENUM_INTRINSIC_EXCEPTION_TYPES(DECLARE_INTRINSIC_EXCEPTION_TYPE)
#undef DECLARE_INTRINSIC_EXCEPTION_TYPE

		GCPointer<ExceptionTypeInstance> typeInstance;
		std::vector<IR::UntaggedValue> arguments;
		Platform::CallStack callStack;
	};

	// Creates an exception type instance.
	RUNTIME_API ExceptionTypeInstance* createExceptionTypeInstance(Compartment* compartment,
																   IR::ExceptionType type,
																   std::string&& debugName);

	// Returns a string that describes the given exception cause.
	RUNTIME_API std::string describeException(const Exception& exception);

	// Returns a string that describes the given exception type.
	RUNTIME_API std::string describeExceptionType(const ExceptionTypeInstance* type);

	// Returns the parameter types for an exception type instance.
	RUNTIME_API IR::TypeTuple getExceptionTypeParameters(const ExceptionTypeInstance* type);

	// Throws a runtime exception.
	[[noreturn]] RUNTIME_API void throwException(ExceptionTypeInstance* type,
												 std::vector<IR::UntaggedValue>&& arguments = {});

	// Calls a thunk and catches any runtime exceptions that occur within it.
	RUNTIME_API void catchRuntimeExceptions(const std::function<void()>& thunk,
											const std::function<void(Exception&&)>& catchThunk);

	typedef void (*UnhandledExceptionHandler)(Exception&&);
	RUNTIME_API void setUnhandledExceptionHandler(UnhandledExceptionHandler handler);

	// Describes an instruction pointer.
	bool describeInstructionPointer(Uptr ip, std::string& outDescription);

	// Describes a call stack.
	RUNTIME_API std::vector<std::string> describeCallStack(const Platform::CallStack& callStack);

	//
	// Functions
	//

	// Invokes a FunctionInstance with the given arguments, and returns the result. The result is
	// returned as a pointer to an untagged value that is stored in the Context that will be
	// overwritten by subsequent calls to invokeFunctionUnchecked. This allows using this function
	// in a call stack that will be forked, since returning the result as a value will be lowered to
	// passing in a pointer to stack memory for most calling conventions.
	RUNTIME_API IR::UntaggedValue* invokeFunctionUnchecked(Context* context,
														   FunctionInstance* function,
														   const IR::UntaggedValue* arguments);

	// Like invokeFunctionUnchecked, but returns a result tagged with its type, and takes arguments
	// as tagged values. If the wrong number or types or arguments are provided, a runtime exception
	// is thrown.
	RUNTIME_API IR::ValueTuple invokeFunctionChecked(Context* context,
													 FunctionInstance* function,
													 const std::vector<IR::Value>& arguments);

	// Returns the type of a FunctionInstance.
	RUNTIME_API IR::FunctionType getFunctionType(FunctionInstance* function);

	//
	// Tables
	//

	// Creates a Table. May return null if the memory allocation fails.
	RUNTIME_API TableInstance* createTable(Compartment* compartment,
										   IR::TableType type,
										   std::string&& debugName);

	// Reads an element from the table. Assumes that index is in bounds.
	RUNTIME_API Object* getTableElement(TableInstance* table, Uptr index);

	// Writes an element to the table. Assumes that index is in bounds, and returns a pointer to the
	// previous value of the element.
	RUNTIME_API Object* setTableElement(TableInstance* table, Uptr index, Object* newValue);

	// Gets the current or maximum size of the table.
	RUNTIME_API Uptr getTableNumElements(TableInstance* table);
	RUNTIME_API Uptr getTableMaxElements(TableInstance* table);

	// Grows or shrinks the size of a table by numElements. Returns the previous size of the table.
	RUNTIME_API Iptr growTable(TableInstance* table, Uptr numElements);
	RUNTIME_API Iptr shrinkTable(TableInstance* table, Uptr numElements);

	//
	// Memories
	//

	// Creates a Memory. May return null if the memory allocation fails.
	RUNTIME_API MemoryInstance* createMemory(Compartment* compartment,
											 IR::MemoryType type,
											 std::string&& debugName);

	// Gets the base address of the memory's data.
	RUNTIME_API U8* getMemoryBaseAddress(MemoryInstance* memory);

	// Gets the current or maximum size of the memory in pages.
	RUNTIME_API Uptr getMemoryNumPages(MemoryInstance* memory);
	RUNTIME_API Uptr getMemoryMaxPages(MemoryInstance* memory);

	// Grows or shrinks the size of a memory by numPages. Returns the previous size of the memory.
	RUNTIME_API Iptr growMemory(MemoryInstance* memory, Uptr numPages);
	RUNTIME_API Iptr shrinkMemory(MemoryInstance* memory, Uptr numPages);

	// Unmaps a range of memory pages within the memory's address-space.
	RUNTIME_API void unmapMemoryPages(MemoryInstance* memory, Uptr pageIndex, Uptr numPages);

	// Validates that an offset range is wholly inside a Memory's virtual address range.
	// Note that this returns an address range that may fault on access, though it's guaranteed not
	// to be mapped by anything other than the given MemoryInstance.
	RUNTIME_API U8* getReservedMemoryOffsetRange(MemoryInstance* memory,
												 Uptr offset,
												 Uptr numBytes);

	// Validates that an offset range is wholly inside a Memory's committed pages.
	RUNTIME_API U8* getValidatedMemoryOffsetRange(MemoryInstance* memory,
												  Uptr offset,
												  Uptr numBytes);

	// Validates an access to a single element of memory at the given offset, and returns a
	// reference to it.
	template<typename Value> Value& memoryRef(MemoryInstance* memory, Uptr offset)
	{
		return *(Value*)getValidatedMemoryOffsetRange(memory, offset, sizeof(Value));
	}

	// Validates an access to multiple elements of memory at the given offset, and returns a pointer
	// to it.
	template<typename Value>
	Value* memoryArrayPtr(MemoryInstance* memory, Uptr offset, Uptr numElements)
	{
		return (Value*)getValidatedMemoryOffsetRange(memory, offset, numElements * sizeof(Value));
	}

	//
	// Globals
	//

	// Creates a GlobalInstance with the specified type and initial value.
	RUNTIME_API GlobalInstance* createGlobal(Compartment* compartment,
											 IR::GlobalType type,
											 IR::Value initialValue);

	// Reads the current value of a global.
	RUNTIME_API IR::Value getGlobalValue(const Context* context, GlobalInstance* global);

	// Writes a new value to a global, and returns the previous value.
	RUNTIME_API IR::Value setGlobalValue(Context* context,
										 GlobalInstance* global,
										 IR::Value newValue);

	//
	// Modules
	//

	struct ImportBindings
	{
		std::vector<FunctionInstance*> functions;
		std::vector<TableInstance*> tables;
		std::vector<MemoryInstance*> memories;
		std::vector<GlobalInstance*> globals;
		std::vector<ExceptionTypeInstance*> exceptionTypes;
	};

	struct Module;
	typedef std::shared_ptr<Module> ModuleRef;
	typedef std::shared_ptr<const Module> ModuleConstRef;
	typedef const std::shared_ptr<Module>& ModuleRefParam;
	typedef const std::shared_ptr<const Module>& ModuleConstRefParam;

	// Compiles an IR module to object code.
	RUNTIME_API ModuleRef compileModule(const IR::Module& irModule);

	// Extracts the compiled object code for a module. This may be used as an input to
	// loadPrecompiledModule to bypass redundant compilations of the module.
	RUNTIME_API std::vector<U8> getObjectCode(ModuleConstRefParam module);

	// Loads a previously compiled module from a combination of an IR module and the object code
	// returned by getObjectCode for the previously compiled module.
	RUNTIME_API ModuleRef loadPrecompiledModule(const IR::Module& irModule,
												const std::vector<U8>& objectCode);

	// Instantiates a compiled module, bindings its imports to the specified objects. May throw a
	// runtime exception for bad segment offsets.
	RUNTIME_API ModuleInstance* instantiateModule(Compartment* compartment,
												  ModuleConstRefParam module,
												  ImportBindings&& imports,
												  std::string&& debugName);

	// Gets the start function of a ModuleInstance.
	RUNTIME_API FunctionInstance* getStartFunction(ModuleInstance* moduleInstance);

	// Gets the default table/memory for a ModuleInstance.
	RUNTIME_API MemoryInstance* getDefaultMemory(ModuleInstance* moduleInstance);
	RUNTIME_API TableInstance* getDefaultTable(ModuleInstance* moduleInstance);

	// Gets an object exported by a ModuleInstance by name.
	RUNTIME_API Object* getInstanceExport(ModuleInstance* moduleInstance, const std::string& name);

	//
	// Compartments
	//

	RUNTIME_API Compartment* createCompartment();

	RUNTIME_API Compartment* cloneCompartment(const Compartment* compartment);

	RUNTIME_API Uptr getCompartmentModuleInstanceId(ModuleInstance* moduleInstance);
	RUNTIME_API Uptr getCompartmentTableId(const TableInstance* table);
	RUNTIME_API Uptr getCompartmentMemoryId(const MemoryInstance* memory);

	RUNTIME_API ModuleInstance* getCompartmentModuleInstanceById(const Compartment* compartment,
																 Uptr moduleInstanceId);
	RUNTIME_API TableInstance* getCompartmentTableById(const Compartment* compartment,
													   Uptr tableId);
	RUNTIME_API MemoryInstance* getCompartmentMemoryById(const Compartment* compartment,
														 Uptr memoryId);

	RUNTIME_API bool isInCompartment(Object* object, const Compartment* compartment);

	//
	// Contexts
	//

	RUNTIME_API Context* createContext(Compartment* compartment);
	RUNTIME_API Compartment* getCompartmentFromContext(const Context* context);

	RUNTIME_API struct ContextRuntimeData* getContextRuntimeData(const Context* context);
	RUNTIME_API Context* getContextFromRuntimeData(struct ContextRuntimeData* contextRuntimeData);

	// Creates a new context, initializing its mutable global state from the given context.
	RUNTIME_API Context* cloneContext(const Context* context, Compartment* newCompartment);
}}
