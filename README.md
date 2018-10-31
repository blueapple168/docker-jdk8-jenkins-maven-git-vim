## docker-jdk8-jenkins-maven-git-vim

Ubuntu 16.04 LTS OpenJDK 1.8.0_181-8u181-b13-1~deb9u1-b13 Maven 3.3.9 Jenkins 2.138.2 git 2.11.0 curl 7.52.1 Vim 8.0.0197

# Usage

```
docker run -p 18080:8080 -p 50000:50000 blueapple/docker-jdk8-jenkins-maven-git-vim
```

NOTE: read below the _build executors_ part for the role of the `50000` port mapping.

This will store the workspace in /var/jenkins_home. All Jenkins data lives in there - including plugins and configuration.
You will probably want to make that an explicit volume so you can manage it and attach to another container for upgrades :

```
docker run -p 18080:8080 -p 50000:50000 -v jenkins_home:/var/jenkins_home blueapple/docker-jdk8-jenkins-maven-git-vim
```

this will automatically create a 'jenkins_home' volume on docker host, that will survive container stop/restart/deletion. 

Avoid using a bind mount from a folder on host into `/var/jenkins_home`, as this might result in file permission issue. If you _really_ need to bind mount jenkins_home, ensure that directory on host is accessible by the jenkins user in container (jenkins user - uid 1000) or use `-u some_other_user` parameter with `docker run`.
