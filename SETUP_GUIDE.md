# 🚀 Quick Setup Guide for Enhanced AI Features

## Prerequisites

1. **Java 11+** installed
2. **Maven 3.6+** installed  
3. **Ollama** installed and running
4. **Python 3.6+** (for testing script)

## Setup Steps

### 1. Install and Setup Ollama

```bash
# Install Ollama (if not already installed)
# For Windows: Download from https://ollama.ai/download
# For Linux/Mac:
curl -fsSL https://ollama.ai/install.sh | sh

# Start Ollama service
ollama serve

# In another terminal, pull the AI model
ollama pull llama2
# or for better performance:
ollama pull llama2:7b-chat
```

### 2. Configure Application Properties

Add/update these properties in `src/main/resources/application.properties`:

```properties
# AI Configuration
spring.ai.ollama.model=llama2
spring.ai.ollama.base-url=http://localhost:11434

# Cache Configuration
app.ai.cache.duration=300000
app.ai.cache.max-size=1000
app.ai.warmup.enabled=true
```

### 3. Run the Application

```bash
# Clean and compile
mvn clean compile

# Run the application
mvn spring-boot:run

# Or run with specific profile
mvn spring-boot:run -Dspring-boot.run.profiles=ai-enhanced
```

### 4. Verify AI Features

**Option A: Using PowerShell (Windows)**
```powershell
# Run test script
.\test_ai_features.ps1

# With verbose output
.\test_ai_features.ps1 -Verbose

# Test specific base URL
.\test_ai_features.ps1 -BaseUrl "http://localhost:8080" -Verbose
```

**Option B: Using Python (All platforms)**
```bash
# Install requests if needed
pip install requests

# Run test script
python test_ai_features.py
```

**Option C: Manual Testing with curl**
```bash
# Test AI Health
curl http://localhost:8080/api/v1/ai/health

# Test Crypto Q&A
curl -X POST http://localhost:8080/api/v1/ai/crypto/question/BTC \
  -H "Content-Type: application/json" \
  -d '{"question": "Should I invest in Bitcoin?"}'

# Test General Q&A
curl -X POST http://localhost:8080/api/v1/ai/crypto/question \
  -H "Content-Type: application/json" \
  -d '{"question": "What is cryptocurrency?"}'

# Test Similar Coins
curl "http://localhost:8080/api/v1/ai/crypto/similar/BTC?limit=5&includeAnalysis=true"

# Test Comparison
curl -X POST http://localhost:8080/api/v1/ai/crypto/compare \
  -H "Content-Type: application/json" \
  -d '{"symbols": ["BTC", "ETH", "ADA"]}'

# Test Investment Recommendations
curl -X POST http://localhost:8080/api/v1/ai/crypto/recommend \
  -H "Content-Type: application/json" \
  -d '{"risk_tolerance": "medium", "investment_type": "long_term", "budget_range": 10000}'
```

## Expected Results

### ✅ Successful Setup Indicators

1. **Application starts without errors**
   - No compilation errors
   - AI services initialize properly
   - Cache warming completes successfully

2. **AI Health Check passes**
   ```json
   {
     "success": true,
     "data": {
       "status": "operational",
       "features": ["Enhanced Q&A", "Similar Coin Recommendations", ...]
     }
   }
   ```

3. **Q&A responses are intelligent and contextual**
   - Responses are >100 characters
   - Include relevant cryptocurrency information
   - Categorize questions correctly

4. **Similar coins recommendations are accurate**
   - Returns 3-5 similar cryptocurrencies
   - Includes similarity scores
   - Provides match reasons

### 🔍 Logs to Monitor

```bash
# Monitor application startup
tail -f application.log | grep -E "(cache warming|AI|Enhanced)"

# Monitor AI Q&A activity
tail -f application.log | grep "Enhanced AI Q&A"

# Monitor similar coin activity  
tail -f application.log | grep "Enhanced similar cryptocurrencies"

# Monitor cache performance
tail -f application.log | grep "cache"
```

## Troubleshooting

### Common Issues

1. **"AI Service Health Check Failed"**
   - Ensure Ollama is running: `ollama serve`
   - Check model is available: `ollama list`
   - Verify port 11434 is accessible

2. **"Slow AI Responses"**
   - Check Ollama model size (7b models are faster than 13b+)
   - Monitor system resources (CPU/Memory)
   - Verify cache warming completed

3. **"Empty/Short AI Responses"**
   - Check Ollama logs for errors
   - Verify model is properly loaded
   - Try restarting Ollama service

4. **"Similar Coins Not Found"**
   - Check if cryptocurrency data is available
   - Verify API services are working
   - Check network connectivity

### Performance Optimization

1. **Faster AI Model**
   ```bash
   # Use a smaller, faster model
   ollama pull llama2:7b-chat
   
   # Update application.properties
   spring.ai.ollama.model=llama2:7b-chat
   ```

2. **Increase Cache Size**
   ```properties
   app.ai.cache.duration=600000  # 10 minutes
   app.ai.cache.max-size=2000    # More cached responses
   ```

3. **Optimize Warmup**
   ```properties
   app.ai.warmup.enabled=true
   app.ai.warmup.popular-symbols=BTC,ETH,ADA,SOL,DOT,AVAX,MATIC,LINK
   ```

## Next Steps

1. **Integrate with Frontend**
   - Add Q&A chat interface
   - Create similar coins recommendation widget
   - Build investment advisory dashboard

2. **Enhance AI Capabilities**
   - Add more question types
   - Implement sentiment analysis
   - Create market prediction models

3. **Scale for Production**
   - Add AI service clustering
   - Implement distributed caching
   - Add monitoring and alerting

## Resources

- **Ollama Documentation**: https://ollama.ai/docs
- **Spring AI Reference**: https://docs.spring.io/spring-ai/reference/
- **API Documentation**: Visit http://localhost:8080/swagger-ui.html after startup
- **Monitor Endpoints**: http://localhost:8080/actuator/health

## Support

If you encounter issues:

1. Check the application logs
2. Run the test scripts for diagnostics
3. Verify Ollama service status
4. Review the troubleshooting section above

The enhanced AI features should provide intelligent, context-aware responses for cryptocurrency questions and smart recommendations for similar coins, making your crypto application much more valuable to users! 🎉
