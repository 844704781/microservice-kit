package com.watermelon.api.client;

import com.watermelon.api.dto.HealthResponse;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;

@FeignClient(name = "nodejs-processor", url = "${NODEJS_PROCESSOR_URL:http://localhost:8002}")
public interface NodejsProcessorClient {
    
    @GetMapping("/health")
    HealthResponse health();
}