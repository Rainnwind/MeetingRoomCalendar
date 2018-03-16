# Prepare Microsoft Windows Server 2016

- Add Server Role "Web Server (IIS), including at least the following features:
  - Common HTTP Features
    - Default Document
    - Directory Browsing
    - HTTP Errors
    - Static Content
  - Health and Diagnostics
    - HTTP Logging
  - Performance
    - Static Content Compression
  - Security
    - Request Filtering
    - Windows Authentication
  - Application Development
    - .Net Extensibility 4.6
    - ASP.NET 4.6
    - ISAPI Extensions
    - ISAPI Filters
  - Management Tools
    - IIS Management Console
    - Management Services
- Install "Web Deploy 3.6" (e.g. file "WebDeploy_amd64_en-US.msi") - include "IIS Deployment Handler" and sub-features
- Install ".NET Core Windows Server Hosting bundle" (e.g. file "DotNetCore.2.0.5-WindowsHosting.exe")
- Restart server (may not be nessesary, but at least re-start IIS and "Web Management Service")

# Create mrc site in IIS

- Add an application pool called mrc to run the **mrc** site with the following properties
  - .NET CLR Version: v4.0
  - Managed Pipeline Mode: Integrated
  - Identity: A domain user that has access to meeting room mailboxes, e.g. **dbbint\!adminmrc**
- Add a site called **mrc** that uses the application pool **mrc** created above and that has the proper bindings, e.g. 
  - mrc.dbb.dk on *:80 (http)
  - http-mrc.live.dbb.dk on *:80 (http)
  - http-mrc.beta.dbb.dk on *:80 (http)
  - http-mrc.ngt.dbb.dk on *:80 (http)

# Publish site in VS 2017