Templates = {}
Templates.IncludeRelativePath =
[[#include "${file}"
]]

Templates.IncludeFullPath =
[[#include <${file}>
]]

Templates.ConstantWrapper =
[[${type} wrapper_${bindingName} ()
{
    return ${name};
}

]]

Templates.SubsystemWrapper =
[[${type} *wrapper_${bindingName} ()
{
    return Urho3D::GetScriptContext ()->GetSubsystem <${type}> ();
}

]]

Templates.CXXArrayToASArray =
[[Urho3D::VectorToArray <${cxxArrayElementType}> (${cxxArrayName}, "Array <${asArrayElementType}>")]]

Templates.CXXArrayToASHandleArray =
[[Urho3D::VectorToHandleArray <${cxxArrayElementType}> (${cxxArrayName}, "Array <${asArrayElementType}>")]]

Templates.ASArrayToCXXArray =
[[Urho3D::ArrayTo${cxxArrayShortType} <${cxxArrayElementType}> (${asArrayName})]]

Templates.StandartRegisterFunction =
[[void Register${name} (asIScriptEngine *engine)
]]

Templates.ClassRegisterFunction =
[[template <class T> void Register${name} (asIScriptEngine *engine, const char *className, bool registerConstructors)
]]

Templates.CallStandartRegister =
[[    Register${name} (engine);
]]

Templates.CallClassRegister =
[[    Register${baseName} <${templateName}> (engine, ${bindingName}, ${registerConstructors});
]]

Templates.DeclareClass =
[[    engine->RegisterObjectType ("${name}", ${size}, ${objectType});
]]

Templates.RegisterSubclass =
[[        Urho3D::RegisterSubclass <${baseName}, ${inheritorName}> (engine, ${baseBindingName}, ${inheritorBindingName});
]]

Templates.RegisterClassBase =
[[    Register${baseName} <T> (engine, className);
]]

Templates.RegisterConstant =
[[    engine->RegisterGlobalFunction ("${bindingType} get_${bindingName} ()", asFUNCTION (wrapper_${bindingName}), asCALL_CDECL);
]]

Templates.RegisterEnumType =
[[    engine->RegisterEnum ("${bindingName}");
]]

Templates.RegisterEnumValue =
[[    engine->RegisterEnumValue ("${bindingEnumName}", "${bindingValue}", ${value});
]]

Templates.RegisterFreeFunction =
[[    engine->RegisterGlobalFunction ("${bindingReturnType} ${bindingName} (${bindingArgs})", asFUNCTION (${name}), asCALL_CDECL);
]]

Templates.RegisterClassConstructor =
[[        engine->RegisterObjectBehaviour (className, asBEHAVE_FACTORY, (Urho3D::String (className) + "@+ f (${wrapperArgs})").CString (), asFUNCTION (${wrapperName}), asCALL_CDECL);
]]

Templates.RegisterClassMethodWithoutWrapper =
[[    engine->RegisterObjectMethod (className, "${bindingReturnType} ${bindingName} (${bindingArgs}) ${modifers}", asMETHOD (T, ${name}), asCALL_THISCALL);
]]

Templates.RegisterClassMethodWithWrapper =
[[    engine->RegisterObjectMethod (className, "${bindingReturnType} ${bindingName} (${bindingArgs}) ${modifers}", asFUNCTION (${wrapperName}), asCALL_CDECL_OBJFIRST);
]]

Templates.RegisterSubsystem =
[[    engine->RegisterGlobalFunction ("${bindingType} @+ get_${bindingName} ()", asFUNCTION (wrapper_${bindingName}), asCALL_CDECL);
]]
return Templates
