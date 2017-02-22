---
layout: page
title: Daily Journal
permalink: /journal/
---

Here's what I've done and not done.

  <ul class="post-list">
    {% for category in site.categories %}
      {% if category.first == "daily-journal" %}
        {% for posts in category %}
         {% for post in posts %}
           {% unless post.date == nil %}
          <li>
            <span class="post-meta">{{ post.date | date: "%b %-d, %Y" }}</span>

            <h2>
              <a class="post-link" href="{{ post.url | prepend: site.baseurl }}">{{ post.title | escape }}</a>
            </h2>
          </li>
            {% endunless %}
          {% endfor %}
        {% endfor %}
      {% endif %}
    {% endfor %}
  </ul>
