
-- Info.lua

-- Implements the g_PluginInfo standard plugin description

g_PluginInfo =
{
	Name = "ItemSpawner",
	Version = "1",
	Date = "2017-05-19",
	-- SourceLocation = "https://github.com/cuberite/Core",
	Description = [[Create a item spawner that spawns random items inside of a specified radius.]],

	Commands =
	{
		["/itemspawner"] =
		{
			Handler = HandleHelpCommand,
			HelpString = "Shows the list of arguments.",
			Subcommands =
			{
				help =
				{
					Handler = HandleHelpCommand,
				},
				create =
				{
					Handler = HandleCreateCommand,
					Permission = "itemspawner.create",
					HelpString = "Create a new item spawner.",
				},
				remove =
				{
					Handler = HandleRemoveCommand,
					Permission = "itemspawner.remove",
					HelpString = "Removes a item spawner.",
				},
				list =
				{
					Handler = HandleListCommand,
					Permission = "itemspawner.list",
					HelpString = "List all item spawners.",
				},
				info =
				{
					Handler = HandleInfoCommand,
					Permission = "itemspawner.info",
					HelpString = "Show info to the item spawner.",
				},
				enable =
				{
					Handler = HandleEnableCommand,
					Permission = "itemspawner.enable",
					HelpString = "Enable the item spawner.",
				},
				disable =
				{
					Handler = HandleDisableCommand,
					Permission = "itemspawner.disable",
					HelpString = "Disable the item spawner.",
				},
				change =
				{
					Subcommands =
					{
						interval =
						{
							Handler = HandleChangeIntervalCommand,
							Permission = "itemspawner.change.interval",
							HelpString = "Change the interval.",
						},
						radius =
						{
							Handler = HandleChangeRadiusCommand,
							Permission = "itemspawner.change.radius",
							HelpString = "Change the radius.",
						},
					},
				},
			},
		},
	},
}
