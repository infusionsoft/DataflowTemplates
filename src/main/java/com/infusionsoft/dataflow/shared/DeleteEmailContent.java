package com.infusionsoft.dataflow.shared;

import static com.google.common.base.Preconditions.checkArgument;

import com.google.cloud.storage.Storage;
import com.google.datastore.v1.Key;
import com.infusionsoft.dataflow.utils.CloudStorageUtils;
import com.infusionsoft.dataflow.utils.DatastoreUtils;
import org.apache.beam.repackaged.beam_sdks_java_core.org.apache.commons.lang3.StringUtils;
import org.apache.beam.sdk.transforms.DoFn;

public class DeleteEmailContent extends DoFn<Key, Key> {

  private final String projectId;
  private final String bucket;

  public DeleteEmailContent(String projectId, String bucket) {
    checkArgument(StringUtils.isNotBlank(projectId), "projectId must not be blank");
    checkArgument(StringUtils.isNotBlank(bucket), "bucket must not be blank");

    this.projectId = projectId;
    this.bucket = bucket;
  }

  @ProcessElement
  public void processElement(ProcessContext context) {
    final Key key = context.element();
    final long id = DatastoreUtils.getId(key);

    final Storage storage = CloudStorageUtils.getStorage(projectId);

    CloudStorageUtils.delete(storage, bucket, id + ".json", id + ".html", id + ".txt");
    context.output(key);
  }
}
