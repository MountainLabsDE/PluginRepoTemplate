#pragma once

#include "CoreMinimal.h"
#include "Modules/ModuleManager.h"

/**
 * The public interface for YourPluginName module
 */
class IYourPluginNameModule : public IModuleInterface
{
public:
	/**
	 * Singleton-like access to this module's interface
	 */
	static inline IYourPluginNameModule& Get()
	{
		return FModuleManager::LoadModuleChecked<IYourPluginNameModule>("YourPluginName");
	}
};