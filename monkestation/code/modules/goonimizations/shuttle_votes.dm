
SUBSYSTEM_DEF(autotransfer)
	name = "Autotransfer Vote"
	flags = SS_KEEP_TIMING | SS_BACKGROUND
	wait = 1 MINUTES

	var/starttime
	var/targettime
	var/called = FALSE

/datum/controller/subsystem/autotransfer/Initialize(timeofday)
	starttime = world.time
	targettime = starttime + 60 MINUTES

	return SS_INIT_SUCCESS

/datum/controller/subsystem/autotransfer/fire()
	if(length(GLOB.player_list) < 25)
		return
	if(world.time > targettime)
		if(called)
			return
		SSvote.initiate_vote(/datum/vote/shuttle_call, "automatic shuttle vote")
		targettime = targettime + 20 MINUTES

/datum/vote/shuttle_call
	name = "Call Shuttle"
	message = "Should we go home?!"

/datum/vote/shuttle_call/can_be_initiated(mob/by_who, forced = FALSE)
	. = ..()
	if(!.)
		return FALSE
		
	if(!SSticker.HasRoundStarted() || SSautotransfer.called)
		return FALSE
	if(length(GLOB.player_list) < 25)
		return FALSE
	if(started_time)
		var/next_allowed_time = SSautotransfer.targettime
		if(next_allowed_time > world.time && !forced)
			message = "A vote was initiated recently. You must wait [DisplayTimeText(next_allowed_time - world.time)] before a shuttle vote can happen!"
			return FALSE

	message = initial(message)

/datum/vote/shuttle_call/New()
	. = ..()
	default_choices = list("Yes", "No")


/datum/vote/shuttle_call/finalize_vote(winning_option)
	if(SSautotransfer.called)
		return
	if(winning_option == "No")
		return
	if(SSshuttle.emergency.mode == SHUTTLE_CALL)
		return
	SSshuttle.admin_emergency_no_recall = TRUE
	SSshuttle.emergency.mode = SHUTTLE_IDLE
	SSshuttle.emergency.request()
	SSautotransfer.called = TRUE
