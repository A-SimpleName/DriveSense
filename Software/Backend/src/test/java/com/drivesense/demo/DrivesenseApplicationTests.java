package com.drivesense.demo;

import com.drivesense.CleanupScheduler;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest
class DrivesenseApplicationTests {

	@MockBean
	private CleanupScheduler cleanupScheduler;

	@Test
	void contextLoads() {
	}

}
