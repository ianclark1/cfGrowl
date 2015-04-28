<!---
	Growl service for coldFusion!
	Author:		David Sirr (david@sparkit.biz)
	Version:	0.1
	Purpose:	Allow users to subscribe to cf apps and recieve data/notifications via Growl
	Notes:		obviously would work best if you've got a static IP as the subscription is mapped to an IP address,
				may be best suited to intranet apps where you're clients IPs may change infrequently.
	Credits:	inspired by growl implementations in java, ruby, and python
				christian cantrell for solving my custom sized byteArray dilemma via an old blog post
	
	Usage:
		1. init CFC with appname
		2. add notification types
		3. register client hosts
		4. send notifications
			sendNotification(notificationType, title, message[, priority = 0, sticky = false])
			
 --->	 

<!--- 
	this is just a test page to test your network settings etc
	this _should_ run anywhere (as long as it's in a JVM)
 --->

<cfscript>
	// register new host
	if(structKeyExists(form,'hostName')){
		application.objGrowl.addHost(host=form.hostName,password=form.hostPassword);
	}
	
	// send notification
	if(structKeyExists(form,'title')){
		application.objGrowl.sendNotification(
			notificationType = form.notificationType, 
			title = form.title, 
			message= form.message, 
			priority = form.priority, 
			sticky = form.isSticky);
	}
</cfscript>

<h1>cfGrowl</h1>
<cfform format="flash" action="index.cfm" height="230" width="250" name="addHost" timeout="180">
	<cfformgroup type="panel" label="Add New Client (host)">
		<cfformgroup type="vertical">
			<cfformitem type="text" style="font-weight:bold;color:black">Remote Client (host_name or IP):</cfformitem>
			<cfformitem type="text" style="font-weight:normal;color:black">tip: avoid 127.0.0.1! use localhost</cfformitem>
			<cfinput type="text" name="hostName" value="#cgi.REMOTE_HOST#" required="true" message="Host required" />
			<cfformitem type="text" style="font-weight:bold;color:black">Client Password:</cfformitem>
			<cfinput type="text" name="hostPassword" value="" required="true" message="Password required" />
			<cfinput type="submit" name="submit" value="Add Host" />
		</cfformgroup>
	</cfformgroup>
</cfform>

<cfif arrayLen(application.objGrowl.getHosts()) GT 0>
	<cfset aNotifications = application.objGrowl.getNotifications() />
	<cfform format="flash" action="index.cfm" height="400" width="500" name="addMessage" timeout="180">
		<cfformgroup type="panel" label="Send Message">
			<cfformgroup type="vertical">
				<cfformitem type="text" style="font-weight:bold;color:black">Title:</cfformitem>
				<cfinput type="text" name="title" value="" required="true" message="Title required" />
				<cfformitem type="text" style="font-weight:bold;color:black">Message:</cfformitem>
				<cfinput type="text" name="message" value="" required="true" message="Message required" />
				<cfformitem type="text" style="font-weight:bold;color:black">Notification Type:</cfformitem>
				<cfselect name="notificationType">
					<cfloop from="1" to="#arrayLen(aNotifications)#" index="i">
						<cfoutput><option value="#aNotifications[i]#">#aNotifications[i]#</option></cfoutput>
					</cfloop>
				</cfselect>
				<cfformitem type="text" style="font-weight:bold;color:black">Priority:</cfformitem>
				<cfselect name="priority">
					<option value="-2">Very Low</option>
					<option value="-1">Moderate</option>
					<option value="0" selected="selected">Normal</option>
					<option value="1">High</option>
					<option value="2">Emergency</option>
				</cfselect>
				<cfif structKeyExists(form,'isSticky') AND form['isSticky'] NEQ false>
					<cfset isSticky = 'yes' />
				<cfelse>
					<cfset isSticky = 'no' />
				</cfif>
				<cfinput type="checkbox" name="isSticky" value="isSticky" checked="#isSticky#" /> 
				<cfinput type="submit" name="submit" value="Send Message" />
			</cfformgroup>
		</cfformgroup>
	</cfform>
</cfif>