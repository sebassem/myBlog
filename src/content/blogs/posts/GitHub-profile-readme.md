---
title: "Make your GitHub profile stand-out!"
images:
  - "https://images.seifbassem.com/images/Posts/GitHub-Profile-Readme/banner.png"
date: 2022-05-30 17:08:42 +0200
tags: ["GitHub"]
categories: ["posts"]
draft: false
---

<!--more-->

If you work in technology whether you are a developer, an IT pro a DBA, a data scientist or something else, most probably you have a GitHub account. You could be an active contributor on the platform or just using content from others' repositories. In all cases, your GitHub account is something that tells a lot about who you are and what impact you are having in your area of expertise, lots of recruiters and hiring managers already look at your GitHub account and activity to evaluate your contributions, skills and ability to learn.

> I'm already very active on GitHub and submit daily PRs and issues, should i keep reading ?
>
> **Yes, please 😄**

Let's take a look at [my GitHub account](https://github.com/sebassem) as an example (it should resemble most of the GitHub accounts ).

  ![Screenshot showing seif bassem's github account](https://images.seifbassem.com/images/Posts/GitHub-Profile-Readme/1.jpg)

We can see some latest repository where I had some activity, on the left we can see some basic information like on Twitter handle, personal blog and place of work. But nothing stands out , pretty standard stuff 🙄. The problem with how my account's landing page looks like is that its pretty much the default look and nothing stands-out from others. Let's see how we can fix that.

## GitHub Profile README to the rescue

GitHub introduced some years back a feature which allows you to crate a customized landing page for your GitHub account where you can basically do whatever customization you would like to make your landing page more personal and more interesting.

The first step is to create a new repository having the same name as your GitHub account. have it configured as public and select the option to add a README. In my case the repository will be named **sebassem** as my account.

  ![Screenshot showing new Repository creation](https://images.seifbassem.com/images/Posts/GitHub-Profile-Readme/2.jpg)

  ![Screenshot showing a newly created repository readme file](https://images.seifbassem.com/images/Posts/GitHub-Profile-Readme/3.jpg)

GitHub detects that we are creating a profile README and adds some boilerplate to be used. Pretty neat 👍

  ![Screenshot showing the readme boilerplate](https://images.seifbassem.com/images/Posts/GitHub-Profile-Readme/4.jpg)

Let's uncomment the markdown code generated and see how it will look like.

  ![Screenshot showing the readme boilerplate uncommented](https://images.seifbassem.com/images/Posts/GitHub-Profile-Readme/5.jpg)

  ![Screenshot showing the readme boilerplate preview](https://images.seifbassem.com/images/Posts/GitHub-Profile-Readme/6.jpg)

It definetly looks good but we will remove it for now and create our own markdown. Don't worry, if you don't know markdown, there are plenty of content that you can use which I will share later in the post.

## Planning my GitHub Profile README

You need to think about what do you want others knowing about you when they visit your GitHub account, for me I would like to showcase the following:

- Basic information about me
- How to reach me ? (Blog, social media acconuts,...etc)
- My latest blog posts and activities
- My current projects and interests
- Some GitHub stats showing my contributions

## Building my GitHub landing page

Lets first type in the basic information markdown

  ![Screenshot showing the about me markdown](https://images.seifbassem.com/images/Posts/GitHub-Profile-Readme/7.jpg)

Next for the "How to reach me" section, we would need to add some HTML code to showcase the social media icons (you can add any icons if you have the URL or already storing them in your repo).

  ![Screenshot showing the how to reach me markdown](https://images.seifbassem.com/images/Posts/GitHub-Profile-Readme/8.jpg)

To add my recent blog posts, I can add them manually and keep them updated or there are some really cool [GitHub actions workflow](https://github.com/gautamkrishnar/blog-post-workflow) that do the job for you.

  ![Screenshot showing the recent blog posts and activities markdown](https://images.seifbassem.com/images/Posts/GitHub-Profile-Readme/9.jpg)

Similar to the social media part, I will add a section for my current projects and interests using HTML.

  ![Screenshot showing the current projects markdown](https://images.seifbassem.com/images/Posts/GitHub-Profile-Readme/10.jpg)

Finally, let's add some GitHub stats to show our contributions and activities. There are lots of ready made code available to generate your stats, all you need to do is provide your GitHub Id and just copy/paste.

  ![Screenshot showing the GitHub stats markdown](https://images.seifbassem.com/images/Posts/GitHub-Profile-Readme/11.jpg)

Let's now look at how my GitHub profile looks like after committing those new tweaks.

  ![Screenshot showing the GitHub profile readme of seif bassm](https://images.seifbassem.com/images/Posts/GitHub-Profile-Readme/12.jpg)

## Resources

Check out this [repository](https://github.com/abhisheknaiidu/awesome-github-profile-readme#tutorials) for inspiration, examples and tools you can use to make your GitHub repository stand out.
