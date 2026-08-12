#include <sys/sysctl.h>
#include <string.h>
#include <unistd.h>
#include <kern_memorystatus.h>
#include <substrate.h>

// Allocated page tables (done by physrw handoff) count towards the physical memory footprint of the process that created them
// Unfortunately that means jetsam kills us if we do it too often
// For launchd, we therefore prevent it from enabling jetsam using this hook

int (*memorystatus_control_orig)(uint32_t command, int32_t pid, uint32_t flags, void *buffer, size_t buffersize);
int memorystatus_control_hook(uint32_t command, int32_t pid, uint32_t flags, void *buffer, size_t buffersize)
{
	// launchd owns the long-lived physrw/trust-cache handoff allocations. Do not
	// allow either form of per-process memory limit to be installed for pid 1.
	// Some iOS versions restore the limit with SET_MEMLIMIT_PROPERTIES after the
	// early TASK_LIMIT/HIGH_WATER calls, which used to leave a fatal limit behind.
	if ((pid == 0 || pid == 1) &&
		(command == MEMORYSTATUS_CMD_SET_JETSAM_TASK_LIMIT ||
		 command == MEMORYSTATUS_CMD_SET_JETSAM_HIGH_WATER_MARK ||
		 command == MEMORYSTATUS_CMD_SET_MEMLIMIT_PROPERTIES)) {
		return 0;
	}
	return memorystatus_control_orig(command, pid, flags, buffer, buffersize);
}

void initJetsamHook(void)
{
	// Install the hook before clearing the current limits so launchd cannot race
	// another limit update between the reset and hook installation.
	MSHookFunction((void *)memorystatus_control, (void *)memorystatus_control_hook, (void **)&memorystatus_control_orig);
	memorystatus_control_orig(MEMORYSTATUS_CMD_SET_JETSAM_TASK_LIMIT, 1, -1, NULL, 0);
	memorystatus_control_orig(MEMORYSTATUS_CMD_SET_JETSAM_HIGH_WATER_MARK, 1, -1, NULL, 0);
}
