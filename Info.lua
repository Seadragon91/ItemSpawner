
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
					HelpString = "Create a new item spawner at player's location.",
				},
				remove =
				{
					Handler = HandleRemoveCommand,
					Permission = "itemspawner.remove",
					HelpString = "Removes a item spawner, will be disabled and deleted.",
				},
				list =
				{
					Handler = HandleListCommand,
					Permission = "itemspawner.list",
					HelpString = "List all item spawners. Names in green are enabled.",
				},
				info =
				{
					Handler = HandleInfoCommand,
					Permission = "itemspawner.info",
					HelpString = "Show info to the item spawner. The position, radius, interval.",
				},
				enable =
				{
					Handler = HandleEnableCommand,
					Permission = "itemspawner.enable",
					HelpString = "Enable the item spawner. Will then start spawning items in the radius at the specified interval.",
				},
				disable =
				{
					Handler = HandleDisableCommand,
					Permission = "itemspawner.disable",
					HelpString = "Disable the item spawner. Stop spawning items. ",
				},
				change =
				{
					Subcommands =
					{
						interval =
						{
							Handler = HandleChangeIntervalCommand,
							Permission = "itemspawner.change.interval",
							HelpString = "Change the interval. The time in seconds, between the spawning.",
						},
						radius =
						{
							Handler = HandleChangeRadiusCommand,
							Permission = "itemspawner.change.radius",
							HelpString = "Change the radius. The radius in blocks around of the spawner.",
						},
					},
				},
			},
		},
	},
}
