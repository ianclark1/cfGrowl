<cfcomponent>
	<cfscript>
		this.name="cfGrowlPOC";
	</cfscript>

	<cffunction name="onApplicationStart" returnType="boolean" output="false">
		<cfscript>
			application.objGrowl = createObject('component','growl').init(appName='cfGrowl:My Application');
	
			// add notifications
			application.objGrowl.addNotification(notification='Company Sales',enabled=true);
			application.objGrowl.addNotification(notification='Site Error',enabled=true);
			application.objGrowl.addNotification(notification='Server Status',enabled=true);
			
			return true;
		</cfscript>
	</cffunction>
	<cffunction name="onRequestStart" output="false">
		<cfscript>
			if(structKeyExists(url,'initApp'))
				onApplicationStart();
		</cfscript>
	</cffunction>
</cfcomponent>