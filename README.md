"# AL-Functional-Development

## Azure Blob Storage Integration for Business Central

This extension provides seamless integration between Microsoft Dynamics 365 Business Central and Azure Blob Storage for efficient document management, specifically for Incoming Documents functionality.

### Overview

The solution automatically stores incoming document attachments in Azure Blob Storage instead of the Business Central database, significantly reducing database size and improving performance while maintaining full functionality.

### Features

#### Incoming Documents Integration
- **Automatic Upload**: When an incoming document attachment is created, it's automatically uploaded to Azure Blob Storage
- **Database Space Optimization**: After upload, the Content field is cleared to save database space
- **Seamless Download**: Documents are automatically retrieved from Azure when needed (export, view, etc.)
- **Automatic Deletion**: When an attachment is deleted, it's also removed from Azure Blob Storage
- **Purchase Order Integration**: View and download incoming document attachments directly from Purchase Orders

#### Azure Blob Storage Management
- **Configuration Setup**: Easy-to-use setup page for Azure Storage Account credentials
- **Connection Testing**: Test your Azure connection before use
- **Blob Management**: View, upload, and download blobs directly from Business Central
- **Secure Authentication**: Uses Shared Access Key authentication

### Architecture

#### Tables
- **ABS Container Setup (74110)**: Stores Azure Storage Account configuration
  - Account Name
  - Container Name
  - Shared Access Key
- **Purchase Order Attachment (74111)**: Tracks custom attachments (optional)

#### Codeunits
- **ABS Storage Functions (74110)**: Core functionality for Azure Blob Storage operations
  - Initialize Client
  - Upload Blob
  - Download Blob
  - Delete Blob
  - List Blobs
  - Get Blob URL
  
- **Incoming Doc Blob Integration (74111)**: Event subscribers for Incoming Documents
  - OnAfterInsertEvent - Uploads attachment to Azure and clears Content field
  - OnBeforeDeleteEvent - Deletes attachment from Azure
  - OnBeforeExport - Downloads attachment from Azure for export
  - OnBeforeNameDrillDown - Downloads and displays attachment from Azure

#### Pages
- **Azure Blob Storage Setup (74110)**: Configuration page for Azure credentials
- **Purchase Order Inc Doc Ext (74112)**: Purchase Order extension with Azure actions
  - Download from Azure Storage
  - View Azure Attachments

#### Page Extensions
- **Purchase Order ABS Ext (74111)**: Original attachment management extension
- **Purchase Order Inc Doc Ext (74112)**: Incoming Document integration extension

### Setup Instructions

#### 1. Azure Storage Account Setup
1. Create an Azure Storage Account in your Azure Portal
2. Create a Blob Container for your documents
3. Generate a Shared Access Key from the Access Keys section

#### 2. Business Central Configuration
1. Search for "Azure Blob Storage Setup" in Business Central
2. Enter the following information:
   - **Primary Key**: DEFAULT (or custom identifier)
   - **Storage Account Name**: Your Azure Storage Account name
   - **Container Name**: The blob container name you created
   - **Shared Access Key**: Copy from Azure Portal
3. Click "Test Connection" to verify the configuration

#### 3. Usage

##### For Incoming Documents:
1. Create or attach documents to Incoming Document records as usual
2. The system automatically:
   - Uploads the attachment to Azure Blob Storage
   - Clears the Content field in the database
   - Maintains all metadata in Business Central

##### From Purchase Orders:
1. Open a Purchase Order
2. Attach an Incoming Document using standard functionality
3. Use the "Download from Azure Storage" action to retrieve attachments
4. Use the "View Azure Attachments" action to see all attachments
5. The IncomingDocAttachFactBox will display attachment information

### Implementation Details

#### File Naming Convention
Files are stored in Azure with the following naming pattern:
```
IncomingDoc_{EntryNo}_{AttachmentName}.{Extension}
```
Example: `IncomingDoc_1001_Invoice.pdf`

#### Blob URL Structure
```
https://{AccountName}.blob.core.windows.net/{ContainerName}/{Filename}
```

#### Event Subscribers

**Table 133 - Incoming Document Attachment**
- **OnAfterInsertEvent**: Uploads content to Azure and clears database field
- **OnBeforeDeleteEvent**: Removes blob from Azure
- **OnBeforeExport**: Retrieves blob from Azure for export

**Table 137 - Inc. Doc. Attachment Overview**
- **OnBeforeNameDrillDown**: Downloads and opens file from Azure

### Benefits

1. **Reduced Database Size**: Attachments are stored in Azure, not in the BC database
2. **Better Performance**: Smaller database improves overall system performance
3. **Scalability**: Azure Blob Storage can handle unlimited document volumes
4. **Cost Efficiency**: Azure Blob Storage is more cost-effective than database storage
5. **Seamless Integration**: Works transparently with standard BC functionality
6. **Backup & DR**: Leverage Azure's redundancy and backup capabilities

### Technical References

This implementation follows Microsoft best practices and is based on:
- [How to Connect to Azure Blob Storage using AL](https://www.mercuriusit.com/how-to-connect-to-azure-blob-storage-using-al/)
- [Dynamics 365 BC: Azure File Share Module](https://demiliani.com/2024/01/19/dynamics-365-business-central-introducing-the-azure-file-share-module/)
- [Business Central Azure Blob Storage Integration](https://www.linkedin.com/pulse/business-central-azure-blob-storage-bert-verbeek/)

### Error Handling

The system includes comprehensive error handling:
- Configuration validation before operations
- Operation response checking
- Informative error messages
- Integration events for custom error handling

### Extensibility

The solution includes integration events for extensibility:
- OnBeforeUploadIncomingDocAttachment
- OnAfterUploadIncomingDocAttachment
- OnUploadIncomingDocAttachmentError
- OnBeforeDeleteFromBlobStorage
- OnAfterDeleteFromBlobStorage
- OnBeforeDownloadFromBlobStorage
- OnAfterDownloadFromBlobStorage
- OnDownloadFromBlobStorageError
- OnAfterNameDrillDownAttachmentOverview
- OnNameDrillDownAttachmentOverviewError

### Troubleshooting

#### Connection Issues
- Verify Azure Storage Account name is correct
- Ensure Shared Access Key is valid and not expired
- Check Container Name matches the Azure portal
- Test connection using the "Test Connection" action

#### Upload/Download Issues
- Verify the container exists and is accessible
- Check file permissions in Azure
- Ensure sufficient storage quota in Azure
- Review Azure Storage logs for detailed errors

#### Incoming Document Issues
- Verify the attachment has content before upload
- Check that the incoming document is properly attached to the purchase order
- Ensure proper permissions for the user

### Security Considerations

1. **Shared Access Keys**: Store securely and rotate regularly
2. **Consider SAS Tokens**: For enhanced security, extend to support SAS tokens
3. **Access Control**: Limit who can modify Azure Blob Storage Setup
4. **Audit Trail**: Monitor Azure Storage access logs
5. **Encryption**: Azure Storage provides encryption at rest by default

### Future Enhancements

Potential improvements for future versions:
- Support for Azure Active Directory authentication
- Blob versioning and retention policies
- Bulk upload/download operations
- Progress indicators for large files
- Thumbnail generation for image files
- Full-text search integration with Azure Cognitive Search
- Container-level security policies
- Automatic archival of old documents

### Support

For issues or questions:
1. Check Azure Blob Storage configuration
2. Review Business Central error logs
3. Test connection using the built-in test action
4. Verify Azure Storage Account status in Azure Portal

---

## License

This extension follows the Microsoft Dynamics 365 Business Central licensing model." 
