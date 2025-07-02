@echo off
echo Starting Crypto Insight Backend with optimized settings for AI processing...

REM Set Java options for better performance
set JAVA_OPTS=-Xmx2g -Xms1g -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -Dspring.profiles.active=dev

REM Start the Spring Boot application
echo Using Java options: %JAVA_OPTS%

mvn spring-boot:run -Dspring-boot.run.jvmArguments="%JAVA_OPTS%"

pause
