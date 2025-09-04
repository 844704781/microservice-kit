package com.watermelon.api.controller;

import com.watermelon.api.client.NodejsProcessorClient;
import com.watermelon.api.client.PythonProcessorClient;
import com.watermelon.api.dto.AggregatedHealthResponse;
import com.watermelon.api.dto.HealthResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.ArrayList;
import java.util.List;

@RestController
@RequiredArgsConstructor
@Slf4j
public class HealthController {
    
    private final PythonProcessorClient pythonProcessorClient;
    private final NodejsProcessorClient nodejsProcessorClient;
    
    @GetMapping("/health")
    public AggregatedHealthResponse health() {
        AggregatedHealthResponse response = new AggregatedHealthResponse();
        response.setCode(0);
        
        List<AggregatedHealthResponse.ModuleHealthData> moduleDataList = new ArrayList<>();
        
        // 检查Python处理器健康状态
        try {
            HealthResponse pythonHealth = pythonProcessorClient.health();
            String pythonStatus = (pythonHealth != null && pythonHealth.getCode() != null && pythonHealth.getCode() == 0) 
                ? "success" : "fail";
            moduleDataList.add(new AggregatedHealthResponse.ModuleHealthData("python", pythonStatus));
        } catch (Exception e) {
            log.error("Failed to call python processor health check", e);
            moduleDataList.add(new AggregatedHealthResponse.ModuleHealthData("python", "fail"));
        }
        
        // 检查Node.js处理器健康状态
        try {
            HealthResponse nodejsHealth = nodejsProcessorClient.health();
            String nodejsStatus = (nodejsHealth != null && nodejsHealth.getCode() != null && nodejsHealth.getCode() == 0) 
                ? "success" : "fail";
            moduleDataList.add(new AggregatedHealthResponse.ModuleHealthData("nodejs", nodejsStatus));
        } catch (Exception e) {
            log.error("Failed to call nodejs processor health check", e);
            moduleDataList.add(new AggregatedHealthResponse.ModuleHealthData("nodejs", "fail"));
        }
        
        response.setData(moduleDataList);
        return response;
    }
}