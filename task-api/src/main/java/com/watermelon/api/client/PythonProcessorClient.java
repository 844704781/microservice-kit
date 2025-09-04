package com.watermelon.api.client;

import com.watermelon.api.dto.HealthResponse;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;

@FeignClient(name = "python-processor", url = "${PYTHON_PROCESSOR_URL:http://localhost:8001}")
public interface PythonProcessorClient {
    
    @GetMapping("/health")
    HealthResponse health();
}