package com.watermelon.api.dto;

import lombok.Data;
import java.util.List;

@Data
public class AggregatedHealthResponse {
    private Integer code;
    private List<ModuleHealthData> data;
    
    @Data
    public static class ModuleHealthData {
        private String module;
        private String data;
        
        public ModuleHealthData(String module, String data) {
            this.module = module;
            this.data = data;
        }
    }
}