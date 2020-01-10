---
title: "Fixing faulty archive behavior with Office365 on Thunderbird"
layout: post
---

I use [Mozilla Thunderbird][1] to view mail on my work Office365 account (mostly because the web interface only supports [top-posting][2] presently, and several mailing lists I participate in rightly denounce this practice). Overall it gets the job done, despite having a very primitive search capability in comparison to the Outlook web app. However, there is one issue I had, which was very difficult to solve: the archive functionality never worked properly. I recently figured out why.

I have Thunderbird configured to archive to a folder on Office365, not locally. Turns out, either by default or because I absentmindedly was fiddling with this one day, I had a setting in place that wanted to archive my mails into yearly archive folders. You can choose between "a single folder", "yearly archived folders", and "monthly archived folders" as of this writing. The "single folder" setting is the only one that works, the others cause the archive button to appear, and you can click it, but does nothing (no errors are displayed either.)

To change this, **go to the Settings for the account in question, then go to the "Copies & Folders" subsection. Find the "Message Archives" fieldset and click "Archive options...", and then select the "single folder" option.** You can have it archive to the "Archive" folder in your Office365 account and then when you click the archive button in Thunderbird, it will function identially to the web interface.

Hope this helps someone else.

[1]: https://www.thunderbird.net/en-US/
[2]: https://answers.microsoft.com/en-us/msoffice/forum/all/how-to-enable-inline-replies-in-web-outlook/944265ea-9a4e-4625-9b29-aadf223334e5


