#include "YourPluginName.h"

#define LOCTEXT_NAMESPACE "FYourPluginNameModule"

/**
 * Module implementation for YourPluginName
 */
class FYourPluginNameModule : public IModuleInterface
{
public:
	/** IModuleInterface implementation */
	virtual void StartupModule() override;
	virtual void ShutdownModule() override;
};

void FYourPluginNameModule::StartupModule()
{
	// This code will execute after your module is loaded into memory; the exact timing is specified in the .uplugin file per-module
	UE_LOG(LogTemp, Log, TEXT("YourPluginName module started"));
}

void FYourPluginNameModule::ShutdownModule()
{
	// This function may be called during shutdown to clean up your module.  For modules that support dynamic reloading,
	// we call this function before unloading the module.
	UE_LOG(LogTemp, Log, TEXT("YourPluginName module stopped"));
}

#undef LOCTEXT_NAMESPACE

IMPLEMENT_MODULE(FYourPluginNameModule, YourPluginName)