# Quick demo of as=badge and as=entry

This is a demo of how to use as=badge, connecting to localhost:3000
to enable manual demonstration.

This should show a linked badge:
<a href="http://localhost:3000/en/projects?as=entry&url=https%3A%2F%2Fgithub.com%2Fcoreinfrastructure%2Fbest-practices-badge"><img src="http://localhost:3000/en/projects?as=badge&url=https%3A%2F%2Fgithub.com%2Fcoreinfrastructure%2Fbest-practices-badge" alt="CII N/A"></a>

This should show linked text (not found):
<a href="http://localhost:3000/en/projects?as=entry&url=https%3A%2F%2FJUNKJUNK"><img src='http://localhost:3000/en/projects?as=badge&url=https%3A%2F%2FJUNKJUNK' alt="CII N/A."></a>

This should show linked text (more than one match, uses pq= instead of url=):
<a href="http://localhost:3000/en/projects?as=entry&pq=https%3A%2F%2F"><img src='http://localhost:3000/en/projects?as=badge&pq=https%3A%2F%2F' alt="CII N/A"></a>
