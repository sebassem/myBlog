---
title: "Building and hosting a blog on Azure Static Web Apps"
images:
  - "https://i.ytimg.com/vi/gWEYfyLu1ew/maxresdefault.jpg"
date: 2021-06-27 17:08:42 +0200
tags: ["Azure Static WebApps","Azure"]
categories: ["posts"]
draft: false

---

<!--more-->

# Overview
I have been thinking a lot lately about having my own blog where i can write about shiny new technologies , use cases of the cloud and anything interesting i stumble upon and i started since last year using Linkedin articles as a blogging platform which helped me a lot to build the right momentum to keep me blogging on a regular basis. 

Using Linkedin for blogging has some benefits like having a larger audience and it takes away a lot of the hassle and spending you would need to build a blog and keep it running (domain , SSL certificate , hosting platform , themes ,...etc) . There were other options like Wordpress and Wix ,...etc which seem very easy and don't require any code but having a previous experience with Wordpress , i could see some costs assosciated with this option and also the need to keep the site plugins up-to-date and the performance wasn't top notch.

 Then in one of Microsoft's build conferences they announced a new service that caught my attention 
 
 🥁🥁🥁🥁🥁🥁🥁 
 
 🔥🔥**Azure Static Web Apps** , which has the promise of getting from code to cloud in a couple of clicks . So i naturally followed a long , watched the service intro video , tried an example and deployed a fully functional web app in a matter of clicks!!!

So i decided to build my own blog using this cool feature , let's explore how the journey went🏃‍♂️🏃‍♂️

## First Stop - 💻 What language to write the App in ?
Azure Web Apps would take care of the code-to-cloud bit but it won't write the code for you , so i needed to figure out how to build the blog with minimal amount of code (Did i jump to fast to Azure static web apps ? 🤔). 

Then i discovered the concept of static website generators , where in a nutshell , your website is not dynamic where you don't need to worry about creating a database or writing code , you would only create a website by building a couple of pages in markdown and modifying some configuration files and the static site generator tool you are using will build a website in HTML/CSS/Javascript that is ready to be served.

So what i needed now is to find one of those tools , pick a theme and start generating some posts and that's it . There are a lot of static site generator tools like Jekyll, Hugo and Gatsby but i chose Hugo as it appeared to have better performance and more popularity in the community.

**A very helpful playlist that helped me get started with Hugo**
<figure class="video_container">
 <iframe width="560" height="315" src="https://www.youtube.com/embed/videoseries?list=PLLAZ4kZ9dFpOnyRlyS-liKL5ReHDcj4G3" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</figure>

After spending maybe one day on Hugo, i was able to get the site configured , some posts written and local testing done , now i was ready to go to the next step of actually looking at Azure static web apps to host my blog.

## Second Stop - ☁️ How does Azure Static Web Apps work ?
The idea is very simple : 
1. You push your app (which can be built using Angular, React, Svelte, and Vue or static site generators ) to source control , in my case Github.
2. Create a new Azure Static Web App 
3. Point it to your repository
4. That's it !!!!
5. No really that's it , no more steps 😄

![Azure Static web apps](https://azurecomcdn.azureedge.net/cvt-d1f914457173f9a29fa48e38d98071dfa717ca0299fa00358be35cd254e17e57/images/page/services/app-service/static/valprop2.png)

There are also some other capabilities like : 
- Integrated API support provided by Azure Functions with the option to link an existing Azure Functions app using a standard account.
- Globally distributed static content, putting content closer to your users.
- Free SSL certificates, which are automatically renewed.
- Custom domains to provide branded customizations to your app.
- Authentication provider integrations with Azure Active Directory, GitHub, and Twitter.
- Generated staging versions powered by pull requests enabling preview versions of your site before publishing.

Ok that's neat ! so how much money would all of that cost ?? 💰💰💰

Actually , all i had to pay for was the domain name of my blog . Azure Static web apps has a free plan with all the capabilities i would need for my personal blog , the only problem was with the maximum size quota of 250MB but i could get around that by serving my images from Azure storage which usually costs pennies. More information on the available plans can be found [here](https://docs.microsoft.com/en-us/azure/static-web-apps/plans#features).


## Third Stop - 🚀 Let's deploy it

1. I created a new GitHub repo and pushed my Hugo source code

![github](http://images.seifbassem.com/myblog/images/Posts/Blog-Azure-Static-Web-Apps/1.PNG)

2. Create a new Azure Static Web App and linked it to my GitHub repo

![New Static App](http://images.seifbassem.com/myblog/images/Posts/Blog-Azure-Static-Web-Apps/2.PNG)

3. After few seconds , the application is created and i can see that it automatically started building my Hugo site to generate the static files

![Workflow](http://images.seifbassem.com/myblog/images/Posts/Blog-Azure-Static-Web-Apps/3.PNG)

4. Finally , i needed to add my custom domain and viola!! the blog is up and running

![Workflow](http://images.seifbassem.com/myblog/images/Posts/Blog-Azure-Static-Web-Apps/4.PNG)

![Workflow](http://images.seifbassem.com/myblog/images/Posts/Blog-Azure-Static-Web-Apps/5.PNG)

> One cool feature is that when you create a new pull request to your repo , it will automatically create a staging web app for you to test your changes before pushing to production 🤯🤯
# Summary
Azure Static Web Apps went into GA just last month but it's incredibly useful to get from code to cloud in a matter of minutes. 

**References**
[Azure Static Web Apps documentation](https://docs.microsoft.com/en-us/azure/static-web-apps/)
  
<figure class="video_container">
 <iframe width="560" height="315" src="https://www.youtube.com/embed/Ta2QjwcO2p8" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</figure>