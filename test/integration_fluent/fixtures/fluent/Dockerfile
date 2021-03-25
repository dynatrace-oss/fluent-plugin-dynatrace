# Copyright 2021 Dynatrace LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM fluent/fluentd:edge

LABEL maintainer="Dyntrace Open Source Engineering <opensource@dynatrace.com>"
USER root

# the build context is the root of the repo to allow access to the plugin rb
COPY test/integration_fluent/fixtures/fluent/entrypoint.sh /fluentd/entrypoint.sh
RUN chmod +x /fluentd/entrypoint.sh

COPY test/integration_fluent/fixtures/fluent/fluent.conf /fluentd/etc/fluent.conf
COPY lib/fluent/plugin/out_dynatrace.rb /fluentd/plugins/
COPY lib/fluent/plugin/dynatrace_constants.rb /fluentd/plugins/

ENTRYPOINT ["tini", "--", "/fluentd/entrypoint.sh"]

USER fluent
