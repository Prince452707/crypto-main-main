package crypto.insight.crypto.service.provider;

import crypto.insight.crypto.model.CryptoData;
import crypto.insight.crypto.model.CryptoIdentity;
import reactor.core.publisher.Mono;

public interface DataProvider {

    Mono<CryptoIdentity> resolveIdentity(String query);

    Mono<CryptoData> fetchData(CryptoIdentity identity);

    String getProviderName();
}
