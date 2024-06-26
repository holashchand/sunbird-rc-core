package dev.sunbirdrc.registry.util;

import com.fasterxml.jackson.databind.JsonNode;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Async;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import dev.sunbirdrc.pojos.AuditRecord;

/**
 * 
 * Save audit details to file system
 *
 */
public class AuditFileWriter {
    private static Logger logger = LoggerFactory.getLogger(AuditFileWriter.class);

	@Async("auditExecutor")
	public void auditToFile(JsonNode auditRecord) throws JsonProcessingException {
		ObjectMapper objectMapper = new ObjectMapper();
		String auditString = objectMapper.writeValueAsString(auditRecord);
		logger.info("{}", auditString);
	}

}
