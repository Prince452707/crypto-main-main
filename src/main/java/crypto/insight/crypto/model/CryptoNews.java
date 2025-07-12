package crypto.insight.crypto.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;
import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class CryptoNews {
    
    @JsonProperty("id")
    private String id;
    
    @JsonProperty("title")
    private String title;
    
    @JsonProperty("body")
    private String body;
    
    @JsonProperty("url")
    private String url;
    
    @JsonProperty("source")
    private String source;
    
    @JsonProperty("imageurl")
    private String imageUrl;
    
    @JsonProperty("published_on")
    private Long publishedOn;
    
    @JsonProperty("source_info")
    private SourceInfo sourceInfo;
    
    @JsonProperty("lang")
    private String lang;
    
    @JsonProperty("tags")
    private String tags;
    
    @JsonProperty("categories")
    private String categories;
    
    // Computed fields
    private LocalDateTime publishedDate;
    private String excerpt;
    
    @Data
    @AllArgsConstructor
    @NoArgsConstructor
    public static class SourceInfo {
        @JsonProperty("name")
        private String name;
        
        @JsonProperty("img")
        private String image;
        
        @JsonProperty("lang")
        private String lang;
    }
    
    // Helper methods
    public LocalDateTime getPublishedDate() {
        if (publishedOn != null) {
            return LocalDateTime.ofEpochSecond(publishedOn, 0, java.time.ZoneOffset.UTC);
        }
        return null;
    }
    
    public String getExcerpt() {
        if (body != null && body.length() > 200) {
            return body.substring(0, 200) + "...";
        }
        return body;
    }
}
