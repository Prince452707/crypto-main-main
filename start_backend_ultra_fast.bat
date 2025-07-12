@echo off
echo Starting Ultra-Fast Crypto Insight Backend...

REM Set ultra-performance Java options
set JAVA_OPTS=-Xmx4g -Xms2g -XX:+UseG1GC -XX:MaxGCPauseMillis=100 -XX:+UnlockExperimentalVMOptions -XX:+UseZGC -Dspring.profiles.active=dev -Djava.awt.headless=true -Dfile.encoding=UTF-8

REM Additional performance optimizations
set JAVA_OPTS=%JAVA_OPTS% -XX:+AggressiveOpts -XX:+UseFastAccessorMethods -XX:+OptimizeStringConcat -XX:+UseCompressedOops -XX:+UseCompressedClassPointers

REM Network optimizations
set JAVA_OPTS=%JAVA_OPTS% -Djava.net.preferIPv4Stack=true -Dnetworkaddress.cache.ttl=60

REM Spring Boot optimizations
set JAVA_OPTS=%JAVA_OPTS% -Dspring.jmx.enabled=false -Dspring.main.lazy-initialization=false

echo Using Java options: %JAVA_OPTS%
echo.
echo 🚀 Starting with ultra-performance optimizations...
echo 💾 Memory: 4GB max, 2GB initial
echo ⚡ GC: ZGC for ultra-low latency
echo 🌐 Network: IPv4 optimized
echo.

mvn spring-boot:run -Dspring-boot.run.jvmArguments="%JAVA_OPTS%"

echo.
echo Backend started! 
echo API available at: http://localhost:8081/api/v1
echo Ultra-fast endpoints: http://localhost:8081/api/v1/ultra-fast
pause
