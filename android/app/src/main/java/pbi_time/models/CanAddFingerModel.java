package pbi_time.models;


public class CanAddFingerModel<T> {
    private String $id;
    private boolean isSuccess;
    private String errorMessage;
    private String successMessage;
    private T content;

    // Getter and setter methods for all fields

    public String getId() {
        return $id;
    }

    public void setId(String $id) {
        this.$id = $id;
    }

    public boolean isSuccess() {
        return isSuccess;
    }

    public void setSuccess(boolean success) {
        isSuccess = success;
    }

    public String getErrorMessage() {
        return errorMessage;
    }

    public void setErrorMessage(String errorMessage) {
        this.errorMessage = errorMessage;
    }

    public String getSuccessMessage() {
        return successMessage;
    }

    public void setSuccessMessage(String successMessage) {
        this.successMessage = successMessage;
    }

    public T getContent() {
        return content;
    }

    public void setContent(T content) {
        this.content = content;
    }
}
